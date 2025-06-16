#!/usr/bin/env python3
"""
llama.cpp Chat Frontend with Dynamic Model Switching
Enhanced Flask web application with seamless model switching capability.
"""

import os
import sqlite3
import requests
import json
import time
import subprocess
import signal
import glob
from datetime import datetime
from flask import Flask, render_template, request, jsonify, g
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-change-this'
app.config['THREADED'] = True


@app.errorhandler(404)
def not_found_error(error):
    """Handle 404 errors with JSON response for API calls."""
    if request.path.startswith('/api/'):
        return jsonify({
            'error': 'Endpoint not found',
            'success': False
        }), 404
    return render_template('404.html'), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors with JSON response for API calls."""
    if request.path.startswith('/api/'):
        return jsonify({
            'error': 'Internal server error',
            'success': False
        }), 500
    return render_template('500.html'), 500


@app.errorhandler(Exception)
def handle_exception(e):
    """Handle all unhandled exceptions."""
    logger.error(f"Unhandled exception: {e}", exc_info=True)

    if request.path.startswith('/api/'):
        return jsonify({
            'error': f'Server error: {str(e)}',
            'success': False
        }), 500
    else:
        # For non-API requests, return HTML error page
        return render_template('error.html', error=str(e)), 500

# Load configuration from JSON file


def load_config():
    """Load configuration from config.json file."""
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        logger.info("Configuration loaded from config.json")
        return config
    except FileNotFoundError:
        logger.warning(
            f"Config file not found at {config_path}, using defaults")
        return get_default_config()
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in config file: {e}, using defaults")
        return get_default_config()


def get_default_config():
    """Get default configuration if config.json is not available."""
    return {
        "timeouts": {
            "llamacpp_timeout": 180,
            "llamacpp_connect_timeout": 15,
            "model_switch_timeout": 60
        },
        "model_options": {
            "temperature": 0.5,
            "top_p": 0.8,
            "top_k": 30,
            "num_predict": 2048,
            "num_ctx": 4096,
            "repeat_penalty": 1.1,
            "stop": ["\n\nHuman:", "\n\nUser:"]
        },
        "performance": {
            "context_history_limit": 10,
            "batch_size": 1,
            "use_mlock": True,
            "use_mmap": True,
            "num_thread": -1,
            "num_gpu": 0
        },
        "system_prompt": "Your name is Bhaai, a helpful, friendly, and knowledgeable AI assistant. You have a warm personality and enjoy helping users solve problems. You're curious about technology and always try to provide practical, actionable advice. You occasionally use light humor when appropriate, but remain professional and focused on being genuinely helpful.",
        "response_optimization": {
            "stream": False,
            "keep_alive": "5m",
            "low_vram": False,
            "f16_kv": True,
            "logits_all": False,
            "vocab_only": False,
            "use_mmap": True,
            "use_mlock": False,
            "embedding_only": False,
            "numa": False
        },
        "models": {
            "directory": "./models",
            "auto_detect": True,
            "default_model": None
        }
    }


# Load configuration
CONFIG = load_config()

# Configuration
LLAMACPP_HOST = os.getenv('LLAMACPP_HOST', 'localhost')
LLAMACPP_PORT = os.getenv('LLAMACPP_PORT', '8080')
LLAMACPP_API_URL = os.getenv(
    'LLAMACPP_API_URL', f'http://{LLAMACPP_HOST}:{LLAMACPP_PORT}')
MODELS_DIR = os.getenv('MODELS_DIR', CONFIG['models']['directory'])
DATABASE_PATH = os.getenv('DATABASE_PATH', 'llamacpp_chat.db')
LLAMACPP_TIMEOUT = CONFIG['timeouts']['llamacpp_timeout']
LLAMACPP_CONNECT_TIMEOUT = CONFIG['timeouts']['llamacpp_connect_timeout']
MODEL_SWITCH_TIMEOUT = CONFIG['timeouts']['model_switch_timeout']

# PID file for llama.cpp server management
LLAMACPP_PID_FILE = os.getenv('LLAMACPP_PID_FILE', 'llamacpp.pid')

# Enhanced database schema with model tracking
SCHEMA = '''
CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    model TEXT NOT NULL,
    model_file TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    model TEXT,
    model_file TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_time_ms INTEGER,
    estimated_tokens INTEGER,
    FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);
'''


def migrate_database():
    """Migrate database to add missing columns."""
    try:
        with sqlite3.connect(DATABASE_PATH) as conn:
            cursor = conn.cursor()

            # Check if model_file column exists in conversations table
            cursor.execute("PRAGMA table_info(conversations)")
            columns = [column[1] for column in cursor.fetchall()]

            if 'model_file' not in columns:
                logger.info("Adding model_file column to conversations table")
                cursor.execute(
                    "ALTER TABLE conversations ADD COLUMN model_file TEXT")
                conn.commit()
                logger.info("Successfully added model_file column")

            # Check if model_file column exists in messages table
            cursor.execute("PRAGMA table_info(messages)")
            columns = [column[1] for column in cursor.fetchall()]

            if 'model_file' not in columns:
                logger.info("Adding model_file column to messages table")
                cursor.execute(
                    "ALTER TABLE messages ADD COLUMN model_file TEXT")
                conn.commit()
                logger.info(
                    "Successfully added model_file column to messages table")

    except Exception as e:
        logger.error(f"Error migrating database: {e}")
        raise


def get_db():
    """Get database connection."""
    if 'db' not in g:
        g.db = sqlite3.connect(DATABASE_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


def close_db(error):
    """Close database connection."""
    db = g.pop('db', None)
    if db is not None:
        db.close()


def init_db():
    """Initialize database with schema."""
    with sqlite3.connect(DATABASE_PATH) as conn:
        conn.executescript(SCHEMA)
        conn.commit()
    logger.info(f"Database initialized: {DATABASE_PATH}")

    # Run migrations
    migrate_database()


@app.teardown_appcontext
def close_db_on_teardown(error):
    close_db(error)


def estimate_tokens(text):
    """Estimate token count based on character length."""
    return max(1, len(text) // 4)


class ModelManager:
    """Manages available models and current model state."""

    @staticmethod
    def get_available_models():
        """Get all available .gguf models in the models directory."""
        if not os.path.exists(MODELS_DIR):
            logger.warning(f"Models directory not found: {MODELS_DIR}")
            return []

        model_files = glob.glob(os.path.join(MODELS_DIR, "*.gguf"))
        models = []

        for model_path in sorted(model_files):
            model_name = os.path.basename(model_path)
            file_size = os.path.getsize(model_path)
            models.append({
                'name': model_name,
                'file_path': model_path,
                'size_mb': round(file_size / (1024 * 1024), 1),
                'size_bytes': file_size
            })

        logger.info(f"Found {len(models)} available models")
        return models

    # @staticmethod
    # def get_current_model():
    #     """Get the currently loaded model from llama.cpp server."""
    #     try:
    #         response = requests.get(
    #             f"{LLAMACPP_API_URL}/v1/models",
    #             timeout=(LLAMACPP_CONNECT_TIMEOUT, 10)
    #         )

    #         if response.status_code == 200:
    #             data = response.json()
    #             if 'data' in data and len(data['data']) > 0:
    #                 return data['data'][0]['id']
    #             return "unknown-model"
    #         return None
    #     except Exception as e:
    #         logger.error(f"Error getting current model: {e}")
    #         return None

    @staticmethod
    def get_current_model():
        """Get the currently loaded model from llama.cpp server."""
        try:
            response = requests.get(
                f"{LLAMACPP_API_URL}/v1/models",
                timeout=(LLAMACPP_CONNECT_TIMEOUT, 10)
            )

            if response.status_code == 200:
                data = response.json()
                if 'data' in data and len(data['data']) > 0:
                    model_path = data['data'][0]['id']
                    # Extract just the filename from the full path
                    import os
                    model_filename = os.path.basename(model_path)
                    logger.info(
                        f"Current model path: {model_path}, filename: {model_filename}")
                    return model_filename
                return "unknown-model"
            return None
        except Exception as e:
            logger.error(f"Error getting current model: {e}")
            return None


class LlamaCppManager:
    """Manages llama.cpp server lifecycle for model switching."""

    @staticmethod
    def is_server_running():
        """Check if llama.cpp server is running."""
        try:
            response = requests.get(
                f"{LLAMACPP_API_URL}/health",
                timeout=(LLAMACPP_CONNECT_TIMEOUT, 5)
            )
            return response.status_code == 200
        except:
            try:
                # Fallback: try models endpoint
                response = requests.get(
                    f"{LLAMACPP_API_URL}/v1/models",
                    timeout=(LLAMACPP_CONNECT_TIMEOUT, 5)
                )
                return response.status_code == 200
            except:
                return False

    @staticmethod
    def stop_server():
        """Stop the llama.cpp server."""
        try:
            if os.path.exists(LLAMACPP_PID_FILE):
                with open(LLAMACPP_PID_FILE, 'r') as f:
                    pid = int(f.read().strip())

                # Try graceful shutdown first
                try:
                    os.kill(pid, signal.SIGTERM)
                    time.sleep(3)

                    # Check if process is still running
                    try:
                        # This doesn't kill, just checks if process exists
                        os.kill(pid, 0)
                        # Still running, force kill
                        os.kill(pid, signal.SIGKILL)
                        logger.info("Force killed llama.cpp server")
                    except OSError:
                        # Process already terminated
                        pass

                except OSError as e:
                    logger.warning(f"Process {pid} not found: {e}")

                # Remove PID file
                os.remove(LLAMACPP_PID_FILE)
                logger.info("Stopped llama.cpp server")
                return True
        except Exception as e:
            logger.error(f"Error stopping server: {e}")

        # Fallback: kill any llama-server processes
        try:
            subprocess.run(["pkill", "-f", "llama-server"],
                           check=False, capture_output=True)
            if os.path.exists(LLAMACPP_PID_FILE):
                os.remove(LLAMACPP_PID_FILE)
            time.sleep(2)
            return True
        except Exception as e:
            logger.error(f"Error with fallback kill: {e}")
            return False

    @staticmethod
    def start_server(model_path):
        """Start llama.cpp server with specified model."""
        try:
            if not os.path.exists(model_path):
                raise FileNotFoundError(f"Model file not found: {model_path}")

            # Determine optimal settings
            threads = CONFIG['performance']['num_thread']
            if threads == -1:
                threads = os.cpu_count() or 4

            context_size = CONFIG['model_options']['num_ctx']
            batch_size = CONFIG['performance']['batch_size']
            gpu_layers = CONFIG['performance']['num_gpu']

            # Build command - use the same format that works in debug script
            cmd = [
                "llama-server",
                "--model", model_path,
                "--host", LLAMACPP_HOST,
                "--port", str(LLAMACPP_PORT),
                "--ctx-size", str(context_size),
                "--batch-size", str(batch_size),
                "--threads", str(threads)
            ]

            # Add GPU layers if configured
            if gpu_layers > 0:
                cmd.extend(["--n-gpu-layers", str(gpu_layers)])

            logger.info(
                f"Starting llama.cpp server with command: {' '.join(cmd)}")

            # Ensure we're in the right working directory
            original_cwd = os.getcwd()
            script_dir = os.path.dirname(os.path.abspath(__file__))
            os.chdir(script_dir)

            try:
                # Start server with explicit environment
                env = os.environ.copy()
                env['PATH'] = os.environ.get('PATH', '')

                # Start server
                with open("llamacpp.log", "a") as log_file:
                    process = subprocess.Popen(
                        cmd,
                        stdout=log_file,
                        stderr=subprocess.STDOUT,
                        env=env,
                        cwd=script_dir
                    )

                # Save PID
                with open(LLAMACPP_PID_FILE, 'w') as f:
                    f.write(str(process.pid))

                logger.info(
                    f"Started llama.cpp server with PID: {process.pid}")

                # Wait for server to be ready - increase attempts and reduce sleep
                max_attempts = 60  # 2 minutes total
                for attempt in range(max_attempts):
                    time.sleep(2)

                    # Check if process is still running
                    if process.poll() is not None:
                        logger.error(
                            f"llama.cpp server process died with return code: {process.returncode}")
                        return False

                    # Check if server is responding
                    try:
                        response = requests.get(
                            f"{LLAMACPP_API_URL}/v1/models",
                            timeout=5
                        )
                        if response.status_code == 200:
                            logger.info(
                                f"llama.cpp server started successfully after {attempt + 1} attempts with model: {os.path.basename(model_path)}")
                            return True
                    except requests.exceptions.RequestException:
                        # Server not ready yet, continue waiting
                        pass

                    if attempt % 10 == 9:  # Log progress every 20 seconds
                        logger.info(
                            f"Still waiting for server... attempt {attempt + 1}/{max_attempts}")

                logger.error("Server failed to start within timeout")
                return False

            finally:
                # Restore original working directory
                os.chdir(original_cwd)

        except Exception as e:
            logger.error(f"Error starting server: {e}")
            return False

    @staticmethod
    def switch_model(model_path):
        """Switch to a different model by restarting the server."""
        logger.info(f"Switching to model: {os.path.basename(model_path)}")

        # Stop current server
        if not LlamaCppManager.stop_server():
            logger.warning(
                "Failed to stop server cleanly, continuing anyway...")

        # Wait a moment for cleanup
        time.sleep(3)

        # Start with new model
        if not LlamaCppManager.start_server(model_path):
            logger.error("Failed to start server with new model")
            return False

        logger.info(
            f"Successfully switched to model: {os.path.basename(model_path)}")
        return True


class LlamaCppAPI:
    """llama.cpp API client with enhanced model awareness."""

    @staticmethod
    def get_models():
        """Get currently loaded model info."""
        try:
            current_model = ModelManager.get_current_model()
            if current_model:
                return [current_model]
            return []
        except Exception as e:
            logger.error(f"Error getting models: {e}")
            return []

    @staticmethod
    def generate_response(model, prompt, conversation_history=None):
        """Generate response from llama.cpp with timing metrics."""
        start_time = time.time()

        try:
            # Get system prompt from config
            system_prompt = CONFIG['system_prompt']

            # Build messages array for chat completion
            messages = [
                {"role": "system", "content": system_prompt}
            ]

            # Add conversation history
            if conversation_history:
                history_limit = CONFIG['performance']['context_history_limit']
                for msg in conversation_history[-history_limit:]:
                    messages.append({
                        "role": msg['role'],
                        "content": msg['content']
                    })

            # Add current user message
            messages.append({"role": "user", "content": prompt})

            # Build payload for OpenAI-compatible endpoint
            payload = {
                "model": model,
                "messages": messages,
                "stream": CONFIG['response_optimization']['stream'],
                "temperature": CONFIG['model_options']['temperature'],
                "top_p": CONFIG['model_options']['top_p'],
                "max_tokens": CONFIG['model_options']['num_predict'],
                "stop": CONFIG['model_options']['stop'],
                "repeat_penalty": CONFIG['model_options']['repeat_penalty'],
            }

            # Add llama.cpp specific parameters if available
            if 'top_k' in CONFIG['model_options']:
                payload['top_k'] = CONFIG['model_options']['top_k']

            response = requests.post(
                f"{LLAMACPP_API_URL}/v1/chat/completions",
                json=payload,
                timeout=(LLAMACPP_CONNECT_TIMEOUT, LLAMACPP_TIMEOUT)
            )

            # Calculate response time
            response_time = int((time.time() - start_time) * 1000)

            if response.status_code == 200:
                data = response.json()

                # Extract response from OpenAI format
                if 'choices' in data and len(data['choices']) > 0:
                    response_text = data['choices'][0]['message']['content']
                else:
                    response_text = 'No response generated'

                # Estimate tokens
                estimated_tokens = estimate_tokens(response_text)

                # Try to get actual token counts from response if available
                usage = data.get('usage', {})
                if 'completion_tokens' in usage:
                    estimated_tokens = usage['completion_tokens']

                return {
                    'response': response_text,
                    'response_time_ms': response_time,
                    'estimated_tokens': estimated_tokens,
                    'completion_tokens': usage.get('completion_tokens'),
                    'prompt_tokens': usage.get('prompt_tokens'),
                    'total_tokens': usage.get('total_tokens')
                }
            else:
                return {
                    'response': f"Error: HTTP {response.status_code}",
                    'response_time_ms': response_time,
                    'estimated_tokens': 0
                }

        except requests.exceptions.ReadTimeout as e:
            response_time = int((time.time() - start_time) * 1000)
            logger.error(f"llama.cpp read timeout: {e}")
            return {
                'response': f"Response timed out after {LLAMACPP_TIMEOUT} seconds.",
                'response_time_ms': response_time,
                'estimated_tokens': 0
            }
        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            logger.error(f"API error: {e}")
            return {
                'response': f"Error: {str(e)}",
                'response_time_ms': response_time,
                'estimated_tokens': 0
            }


class ConversationManager:
    """Enhanced conversation management with model tracking."""

    @staticmethod
    def create_conversation(title, model, model_file=None):
        """Create a new conversation with model info."""
        db = get_db()
        cursor = db.execute(
            'INSERT INTO conversations (title, model, model_file) VALUES (?, ?, ?)',
            (title, model, model_file)
        )
        db.commit()
        return cursor.lastrowid

    @staticmethod
    def get_conversations():
        """Get all conversations ordered by last update."""
        db = get_db()
        return db.execute(
            'SELECT * FROM conversations ORDER BY updated_at DESC'
        ).fetchall()

    @staticmethod
    def get_conversation(conversation_id):
        """Get conversation by ID."""
        db = get_db()
        return db.execute(
            'SELECT * FROM conversations WHERE id = ?',
            (conversation_id,)
        ).fetchone()

    @staticmethod
    def update_conversation_timestamp(conversation_id):
        """Update conversation timestamp."""
        db = get_db()
        db.execute(
            'UPDATE conversations SET updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            (conversation_id,)
        )
        db.commit()

    @staticmethod
    def update_conversation_model(conversation_id, model, model_file=None):
        """Update conversation model info."""
        db = get_db()
        db.execute(
            'UPDATE conversations SET model = ?, model_file = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            (model, model_file, conversation_id)
        )
        db.commit()

    @staticmethod
    def delete_conversation(conversation_id):
        """Delete conversation and all messages."""
        db = get_db()
        db.execute('DELETE FROM conversations WHERE id = ?',
                   (conversation_id,))
        db.commit()

    @staticmethod
    def add_message(conversation_id, role, content, model=None, model_file=None, response_time_ms=None, estimated_tokens=None):
        """Add message to conversation with model info and metrics."""
        db = get_db()
        db.execute(
            'INSERT INTO messages (conversation_id, role, content, model, model_file, response_time_ms, estimated_tokens) VALUES (?, ?, ?, ?, ?, ?, ?)',
            (conversation_id, role, content, model,
             model_file, response_time_ms, estimated_tokens)
        )
        db.commit()
        ConversationManager.update_conversation_timestamp(conversation_id)

    @staticmethod
    def get_messages(conversation_id):
        """Get all messages for a conversation."""
        db = get_db()
        return db.execute(
            'SELECT * FROM messages WHERE conversation_id = ? ORDER BY timestamp',
            (conversation_id,)
        ).fetchall()

    @staticmethod
    def get_conversation_stats(conversation_id):
        """Get conversation statistics."""
        db = get_db()
        stats = db.execute('''
            SELECT
                COUNT(*) as total_messages,
                COUNT(CASE WHEN role = 'assistant' THEN 1 END) as assistant_messages,
                AVG(CASE WHEN role = 'assistant' AND response_time_ms IS NOT NULL THEN response_time_ms END) as avg_response_time,
                SUM(CASE WHEN role = 'assistant' AND estimated_tokens IS NOT NULL THEN estimated_tokens END) as total_tokens
            FROM messages
            WHERE conversation_id = ?
        ''', (conversation_id,)).fetchone()

        return dict(stats) if stats else {}

# Routes


@app.route('/')
def index():
    """Main chat interface."""
    return render_template('index.html')


@app.route('/api/models/available')
def api_available_models():
    """Get all available models in the models directory."""
    try:
        models = ModelManager.get_available_models()
        current_model = ModelManager.get_current_model()

        return jsonify({
            'models': models,
            'current_model': current_model,
            'count': len(models),
            'models_dir': MODELS_DIR
        })
    except Exception as e:
        logger.error(f"Error in /api/models/available endpoint: {e}")
        return jsonify({
            'models': [],
            'current_model': None,
            'count': 0,
            'error': str(e),
            'models_dir': MODELS_DIR
        }), 500


@app.route('/api/models')
def api_models():
    """Get currently loaded model."""
    try:
        models = LlamaCppAPI.get_models()
        current_model = ModelManager.get_current_model()

        return jsonify({
            'models': models,
            'current_model': current_model,
            'count': len(models),
            'llamacpp_url': LLAMACPP_API_URL
        })
    except Exception as e:
        logger.error(f"Error in /api/models endpoint: {e}")
        return jsonify({
            'models': [],
            'current_model': None,
            'count': 0,
            'error': str(e),
            'llamacpp_url': LLAMACPP_API_URL
        }), 500


@app.route('/api/models/switch', methods=['POST'])
def api_switch_model():
    """Switch to a different model."""
    try:
        data = request.get_json()
        model_name = data.get('model_name')

        if not model_name:
            return jsonify({'error': 'Model name is required'}), 400

        # Find the model file
        model_path = os.path.join(MODELS_DIR, model_name)
        if not os.path.exists(model_path):
            return jsonify({'error': f'Model file not found: {model_name}'}), 404

        # Switch model
        logger.info(f"Switching to model: {model_name}")
        success = LlamaCppManager.switch_model(model_path)

        if success:
            # Verify the switch was successful
            time.sleep(2)  # Give server time to fully initialize
            current_model = ModelManager.get_current_model()

            return jsonify({
                'success': True,
                'message': f'Successfully switched to {model_name}',
                'current_model': current_model,
                'model_file': model_name
            })
        else:
            return jsonify({
                'error': f'Failed to switch to model: {model_name}',
                'success': False
            }), 500

    except Exception as e:
        logger.error(f"Error switching model: {e}")
        return jsonify({
            'error': f'Error switching model: {str(e)}',
            'success': False
        }), 500


@app.route('/api/server/status')
def api_server_status():
    """Get server status and current model info."""
    try:
        is_running = LlamaCppManager.is_server_running()
        current_model = ModelManager.get_current_model() if is_running else None

        return jsonify({
            'server_running': is_running,
            'current_model': current_model,
            'llamacpp_url': LLAMACPP_API_URL
        })
    except Exception as e:
        logger.error(f"Error checking server status: {e}")
        return jsonify({
            'server_running': False,
            'current_model': None,
            'error': str(e)
        }), 500

# Existing routes with enhanced model tracking...


@app.route('/api/conversations')
def api_conversations():
    """Get all conversations."""
    try:
        conversations = ConversationManager.get_conversations()
        return jsonify({
            'conversations': [dict(conv) for conv in conversations],
            'success': True
        })
    except Exception as e:
        logger.error(f"Error loading conversations: {e}")
        return jsonify({
            'conversations': [],
            'error': f'Failed to load conversations: {str(e)}',
            'success': False
        }), 500


@app.route('/api/conversations', methods=['POST'])
def api_create_conversation():
    """Create new conversation with model info."""
    try:
        data = request.get_json()
        logger.info(f"Creating conversation with data: {data}")

        if not data:
            data = {}

        title = data.get('title', 'New Chat')
        model = data.get('model', 'unknown')
        model_file = data.get('model_file')

        # If no model_file provided, try to get current model
        if not model_file:
            try:
                available_models = ModelManager.get_available_models()
                current_model = ModelManager.get_current_model()
                logger.info(
                    f"Available models: {len(available_models)}, Current model: {current_model}")

                # Try to match current model to file
                if current_model and available_models:
                    for available_model in available_models:
                        if current_model in available_model['name']:
                            model_file = available_model['name']
                            model = current_model
                            break

                # If no match found but we have available models, use the first one
                if not model_file and available_models:
                    model_file = available_models[0]['name']
                    model = available_models[0]['name']
                    logger.info(f"Using first available model: {model_file}")

            except Exception as e:
                logger.warning(f"Error detecting current model: {e}")
                # Continue with default values
                pass

        # Create conversation
        logger.info(
            f"Creating conversation: title='{title}', model='{model}', model_file='{model_file}'")
        conv_id = ConversationManager.create_conversation(
            title, model, model_file)
        logger.info(f"Created conversation with ID: {conv_id}")

        response_data = {
            'conversation_id': conv_id,
            'success': True,
            'model': model,
            'model_file': model_file
        }
        logger.info(f"Returning response: {response_data}")

        return jsonify(response_data)

    except Exception as e:
        logger.error(f"Error creating conversation: {e}", exc_info=True)
        return jsonify({
            'error': f'Failed to create conversation: {str(e)}',
            'success': False
        }), 500


@app.route('/api/conversations/<int:conversation_id>')
def api_get_conversation(conversation_id):
    """Get conversation with messages and stats."""
    try:
        logger.info(f"Loading conversation ID: {conversation_id}")

        conversation = ConversationManager.get_conversation(conversation_id)
        logger.info(
            f"Found conversation: {dict(conversation) if conversation else None}")

        if not conversation:
            logger.warning(f"Conversation {conversation_id} not found")
            return jsonify({
                'error': 'Conversation not found',
                'success': False
            }), 404

        messages = ConversationManager.get_messages(conversation_id)
        logger.info(
            f"Found {len(messages)} messages for conversation {conversation_id}")

        stats = ConversationManager.get_conversation_stats(conversation_id)
        logger.info(f"Stats for conversation {conversation_id}: {stats}")

        response_data = {
            'conversation': dict(conversation),
            'messages': [dict(msg) for msg in messages],
            'stats': stats,
            'success': True
        }
        logger.info(f"Returning conversation data: {response_data}")

        return jsonify(response_data)

    except Exception as e:
        logger.error(
            f"Error loading conversation {conversation_id}: {e}", exc_info=True)
        return jsonify({
            'error': f'Failed to load conversation: {str(e)}',
            'success': False
        }), 500


@app.route('/api/conversations/<int:conversation_id>', methods=['DELETE'])
def api_delete_conversation(conversation_id):
    """Delete conversation."""
    try:
        # Check if conversation exists first
        conversation = ConversationManager.get_conversation(conversation_id)
        if not conversation:
            return jsonify({
                'error': 'Conversation not found',
                'success': False
            }), 404

        ConversationManager.delete_conversation(conversation_id)
        return jsonify({
            'success': True,
            'message': 'Conversation deleted successfully'
        })
    except Exception as e:
        logger.error(f"Error deleting conversation {conversation_id}: {e}")
        return jsonify({
            'error': f'Failed to delete conversation: {str(e)}',
            'success': False
        }), 500


@app.route('/api/conversations/<int:conversation_id>', methods=['PUT'])
def api_update_conversation(conversation_id):
    """Update conversation (rename)."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({
                'error': 'No data provided',
                'success': False
            }), 400

        new_title = data.get('title', '').strip()

        if not new_title:
            return jsonify({
                'error': 'Title cannot be empty',
                'success': False
            }), 400

        if len(new_title) > 100:
            return jsonify({
                'error': 'Title too long (max 100 characters)',
                'success': False
            }), 400

        # Update the conversation title
        db = get_db()
        result = db.execute(
            'UPDATE conversations SET title = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            (new_title, conversation_id)
        )
        db.commit()

        if result.rowcount == 0:
            return jsonify({
                'error': 'Conversation not found',
                'success': False
            }), 404

        return jsonify({
            'success': True,
            'title': new_title,
            'message': 'Conversation updated successfully'
        })
    except Exception as e:
        logger.error(f"Error updating conversation {conversation_id}: {e}")
        return jsonify({
            'error': f'Failed to update conversation: {str(e)}',
            'success': False
        }), 500


@app.route('/api/chat', methods=['POST'])
def api_chat():
    """Send message and get response with enhanced model tracking."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({
                'error': 'No data provided',
                'success': False
            }), 400

        conversation_id = data.get('conversation_id')
        message = data.get('message')
        model = data.get('model', 'unknown')
        requested_model_file = data.get('model_file')

        if not conversation_id or not message:
            return jsonify({
                'error': 'Missing conversation_id or message',
                'success': False
            }), 400

        # Get current conversation to check if model switch is needed
        conversation = ConversationManager.get_conversation(conversation_id)
        if not conversation:
            return jsonify({
                'error': 'Conversation not found',
                'success': False
            }), 404

        current_model_file = None

        # If a specific model was requested, try to switch to it
        if requested_model_file:
            try:
                current_model = ModelManager.get_current_model()
                available_models = ModelManager.get_available_models()

                # Check if we need to switch models
                model_needs_switch = True
                for available_model in available_models:
                    if (available_model['name'] == requested_model_file and
                            current_model and requested_model_file in current_model):
                        model_needs_switch = False
                        break

                if model_needs_switch:
                    model_path = os.path.join(MODELS_DIR, requested_model_file)
                    if os.path.exists(model_path):
                        logger.info(
                            f"Switching to requested model: {requested_model_file}")
                        success = LlamaCppManager.switch_model(model_path)
                        if not success:
                            return jsonify({
                                'error': f'Failed to switch to model: {requested_model_file}',
                                'success': False
                            }), 500

                        # Update conversation model
                        ConversationManager.update_conversation_model(
                            conversation_id, requested_model_file, requested_model_file
                        )

                current_model_file = requested_model_file
            except Exception as e:
                logger.warning(f"Error handling model switch: {e}")
                # Continue with current model
                pass
        else:
            # Use current model
            try:
                current_model = ModelManager.get_current_model()
                available_models = ModelManager.get_available_models()

                # Try to determine current model file
                for available_model in available_models:
                    if current_model and current_model in available_model['name']:
                        current_model_file = available_model['name']
                        break
            except Exception as e:
                logger.warning(f"Error detecting current model: {e}")
                pass

        # Add user message
        user_tokens = estimate_tokens(message)
        ConversationManager.add_message(
            conversation_id, 'user', message, model, current_model_file, None, user_tokens
        )

        # Get conversation history for context
        messages = ConversationManager.get_messages(conversation_id)
        history = [{'role': msg['role'], 'content': msg['content']}
                   for msg in messages[:-1]]

        # Generate response with metrics
        response_data = LlamaCppAPI.generate_response(model, message, history)

        # Add assistant response with metrics and model info
        ConversationManager.add_message(
            conversation_id,
            'assistant',
            response_data['response'],
            model,
            current_model_file,
            response_data['response_time_ms'],
            response_data['estimated_tokens']
        )

        return jsonify({
            'response': response_data['response'],
            'model': model,
            'model_file': current_model_file,
            'response_time_ms': response_data['response_time_ms'],
            'estimated_tokens': response_data['estimated_tokens'],
            'success': True,
            'metrics': {
                'completion_tokens': response_data.get('completion_tokens'),
                'prompt_tokens': response_data.get('prompt_tokens'),
                'total_tokens': response_data.get('total_tokens')
            }
        })
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        return jsonify({
            'error': f'Chat request failed: {str(e)}',
            'success': False
        }), 500


@app.route('/api/search')
def api_search():
    """Search conversations and messages."""
    try:
        query = request.args.get('q', '').strip()
        if not query:
            return jsonify({
                'results': [],
                'success': True
            })

        db = get_db()
        results = db.execute('''
            SELECT DISTINCT c.id, c.title, c.model, c.model_file, c.updated_at,
                   m.content, m.role, m.timestamp, m.response_time_ms, m.estimated_tokens
            FROM conversations c
            JOIN messages m ON c.id = m.conversation_id
            WHERE m.content LIKE ? OR c.title LIKE ?
            ORDER BY c.updated_at DESC
            LIMIT 50
        ''', (f'%{query}%', f'%{query}%')).fetchall()

        return jsonify({
            'results': [dict(result) for result in results],
            'success': True
        })
    except Exception as e:
        logger.error(f"Error in search endpoint: {e}")
        return jsonify({
            'results': [],
            'error': f'Search failed: {str(e)}',
            'success': False
        }), 500


@app.route('/api/stats/<int:conversation_id>')
def api_conversation_stats(conversation_id):
    """Get detailed statistics for a conversation."""
    try:
        stats = ConversationManager.get_conversation_stats(conversation_id)

        # Get additional detailed stats
        db = get_db()
        detailed_stats = db.execute('''
            SELECT
                role,
                COUNT(*) as count,
                AVG(LENGTH(content)) as avg_length,
                SUM(estimated_tokens) as total_tokens,
                AVG(response_time_ms) as avg_response_time
            FROM messages
            WHERE conversation_id = ?
            GROUP BY role
        ''', (conversation_id,)).fetchall()

        return jsonify({
            'summary': stats,
            'by_role': [dict(stat) for stat in detailed_stats],
            'success': True
        })
    except Exception as e:
        logger.error(
            f"Error getting stats for conversation {conversation_id}: {e}")
        return jsonify({
            'summary': {},
            'by_role': [],
            'error': f'Failed to get statistics: {str(e)}',
            'success': False
        }), 500


if __name__ == '__main__':
    # Initialize database
    init_db()

    # Check llama.cpp connection
    models = LlamaCppAPI.get_models()
    if models:
        logger.info(f"Connected to llama.cpp. Available models: {models}")
    else:
        logger.warning("Could not connect to llama.cpp or no models available")

    # Check available models in directory
    available_models = ModelManager.get_available_models()
    logger.info(
        f"Found {len(available_models)} models in directory: {[m['name'] for m in available_models]}")

    # Log current configuration
    logger.info(f"llama.cpp timeout: {LLAMACPP_TIMEOUT}s")
    logger.info(f"Model switch timeout: {MODEL_SWITCH_TIMEOUT}s")
    logger.info(
        f"Context history limit: {CONFIG['performance']['context_history_limit']} messages")
    logger.info(f"Temperature: {CONFIG['model_options']['temperature']}")

    # Run the app with threading enabled
    flask_host = os.getenv('FLASK_HOST', '0.0.0.0')
    flask_port = int(os.getenv('FLASK_PORT', 3000))

    app.run(
        host=flask_host,
        port=flask_port,
        debug=os.getenv('DEBUG', 'False').lower() == 'true',
        threaded=True
    )
