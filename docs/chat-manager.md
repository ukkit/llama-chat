# Chat Manager Services Documentation

**Complete reference for chat-manager.sh - Enhanced llama-chat Management Script**

The chat-manager.sh script is a comprehensive service management tool that provides dynamic model switching, health monitoring, and intelligent process management for your llama-chat installation.

## 📋 Table of Contents

- [Core Service Management](#-core-service-management)
- [Individual Service Control](#-individual-service-control)
- [Model Management](#-model-management)
- [Monitoring & Health](#-monitoring--health)
- [Logs & Debugging](#-logs--debugging)
- [Maintenance & Utilities](#-maintenance--utilities)
- [Configuration](#-configuration)
- [Advanced Usage](#-advanced-usage)
- [Exit Codes](#-exit-codes)

---

## 🚀 Core Service Management

### `start` - Start All Services
Starts llama.cpp server, Flask application, and health monitoring service.

**Usage:**
```bash
./chat-manager.sh start [model-filename]
```

**Examples:**
```bash
# Start all services with auto-detected model
./chat-manager.sh start

# Start with specific model
./chat-manager.sh start qwen2.5-0.5b-instruct-q4_0.gguf

# Start with model from different path
./chat-manager.sh start /path/to/custom-model.gguf
```

**What it does:**
1. Starts llama.cpp server (port 8120)
2. Starts Flask web application (port 3333)
3. Starts health monitoring service
4. Waits for all services to be ready
5. Reports startup status and URLs

---

### `stop` - Stop All Services
Gracefully stops all running services with intelligent cleanup.

**Usage:**
```bash
./chat-manager.sh stop
```

**Examples:**
```bash
# Standard stop
./chat-manager.sh stop

# Stop with verbose output
DEBUG=true ./chat-manager.sh stop
```

**What it does:**
1. Stops health monitor first
2. Gracefully shuts down Flask application
3. Stops llama.cpp server
4. Cleans up orphaned processes
5. Removes PID files
6. Verifies ports are free

---

### `restart` - Restart All Services
Stops and starts all services with enhanced cleanup.

**Usage:**
```bash
./chat-manager.sh restart [model-filename]
```

**Examples:**
```bash
# Standard restart
./chat-manager.sh restart

# Restart with different model
./chat-manager.sh restart phi3-mini-4k-instruct-q4.gguf

# Restart with cleanup delay
./chat-manager.sh restart && sleep 10
```

**What it does:**
1. Performs graceful shutdown of all services
2. Kills orphaned processes on configured ports
3. Waits for complete cleanup (5 seconds)
4. Starts services with optional model specification

---

### `status` - Show Detailed Service Status
Displays comprehensive status information for all services and system health.

**Usage:**
```bash
./chat-manager.sh status
```

**Example Output:**
```
╔══════════════════════════════════════╗
║      Enhanced llama-chat Manager     ║
║     Dynamic Model Switching          ║
╚══════════════════════════════════════╝

Service Status:
===============
● llama-server (PID: 12345) - Running
● Flask app (PID: 12346) - Running  
● Health monitor (PID: 12347) - Running

Server Health:
==============
✓ llama.cpp API responding
  Current model: qwen2.5-0.5b-instruct-q4_0.gguf
✓ Flask API responding

Configuration:
==============
Install Directory: /home/user/llama-chat
Models Directory:  /home/user/llama-chat/models
llama.cpp API:     http://127.0.0.1:8120
Flask Web UI:      http://127.0.0.1:3333
GPU Layers:        0
Context Size:      4096
Model Switch Timeout: 60s
Auto Restart:      true

Available Models:
=================
  • qwen2.5-0.5b-instruct-q4_0.gguf (394M) [CURRENT]
  • phi3-mini-4k-instruct-q4.gguf (2.3G)
  • llama3.2-1b-instruct-q4.gguf (1.3G)
```

---

## 🔧 Individual Service Control

### `start-llamacpp` - Start llama.cpp Server Only
Starts only the llama.cpp inference server.

**Usage:**
```bash
./chat-manager.sh start-llamacpp [model-filename]
```

**Examples:**
```bash
# Start with auto-detected model
./chat-manager.sh start-llamacpp

# Start with specific model
./chat-manager.sh start-llamacpp phi3-mini-4k-instruct-q4.gguf

# Start with custom parameters via environment
GPU_LAYERS=32 ./chat-manager.sh start-llamacpp
```

**What it does:**
1. Checks if server is already running
2. Verifies port 8120 is available
3. Finds and validates model file
4. Starts llama-server with optimized parameters
5. Waits for API to be responsive
6. Reports model loaded and endpoint URL

**Aliases:** `start-llama`, `start-server`

---

### `start-flask` - Start Flask Application Only
Starts only the web interface application.

**Usage:**
```bash
./chat-manager.sh start-flask
```

**Examples:**
```bash
# Standard start
./chat-manager.sh start-flask

# Start with custom ports
FLASK_PORT=8080 ./chat-manager.sh start-flask

# Start with debug mode
DEBUG=true ./chat-manager.sh start-flask
```

**What it does:**
1. Checks if Flask is already running
2. Verifies port 3333 is available
3. Sets up Python virtual environment
4. Validates app.py exists
5. Starts Flask with environment variables
6. Waits for web interface to respond

**Aliases:** `start-web`, `start-app`

---

### `start-monitor` - Start Health Monitoring Service
Starts the automatic health monitoring and restart service.

**Usage:**
```bash
./chat-manager.sh start-monitor
```

**Examples:**
```bash
# Start monitor with default settings
./chat-manager.sh start-monitor

# Start with custom check interval
HEALTH_CHECK_INTERVAL=60 ./chat-manager.sh start-monitor
```

**What it does:**
1. Checks if monitor is already running
2. Starts background monitoring process
3. Monitors both llama.cpp and Flask services
4. Automatically restarts crashed services (if enabled)
5. Logs all monitoring activity

---

### Stop Individual Services

**`stop-llamacpp`** - Stop llama.cpp server only
```bash
./chat-manager.sh stop-llamacpp
```

**`stop-flask`** - Stop Flask application only
```bash
./chat-manager.sh stop-flask
```

**`stop-monitor`** - Stop health monitoring service
```bash
./chat-manager.sh stop-monitor
```

**Aliases:** `stop-llama`, `stop-server`, `stop-web`, `stop-app`

---

## 🤖 Model Management

### `switch-model` - Dynamic Model Switching
Switch to a different model without restarting Flask or losing conversations.

**Usage:**
```bash
./chat-manager.sh switch-model <model-filename>
```

**Examples:**
```bash
# Switch to different model
./chat-manager.sh switch-model phi3-mini-4k-instruct-q4.gguf

# Switch back to smaller model
./chat-manager.sh switch-model qwen2.5-0.5b-instruct-q4_0.gguf

# Switch with verification
./chat-manager.sh switch-model new-model.gguf && ./chat-manager.sh status
```

**What it does:**
1. Validates new model file exists
2. Gracefully stops current llama.cpp server
3. Waits for cleanup (3 seconds)
4. Starts server with new model
5. Verifies new model is loaded successfully
6. Reports success/failure

**Error handling:**
- Shows available models if file not found
- Attempts to restart original model if switch fails
- Provides detailed error messages

**Alias:** `switch`

---

### `list-models` - Show Available Models
Display detailed information about all available .gguf models.

**Usage:**
```bash
./chat-manager.sh list-models
```

**Example Output:**
```bash
Found 3 model(s):

  📄 qwen2.5-0.5b-instruct-q4_0.gguf [CURRENT]
     Size: 394M, Modified: 2024-06-15
     Path: /home/user/llama-chat/models/qwen2.5-0.5b-instruct-q4_0.gguf

  📄 phi3-mini-4k-instruct-q4.gguf
     Size: 2.3G, Modified: 2024-06-10
     Path: /home/user/llama-chat/models/phi3-mini-4k-instruct-q4.gguf

  📄 llama3.2-1b-instruct-q4.gguf
     Size: 1.3G, Modified: 2024-06-12
     Path: /home/user/llama-chat/models/llama3.2-1b-instruct-q4.gguf
```

**Information shown:**
- Model filename with current model indicator
- File size in human-readable format
- Last modified date
- Full file path
- Total count of available models

**Alias:** `models`

---

### `download-model` - Download New Models
Download .gguf models from URLs with progress tracking.

**Usage:**
```bash
./chat-manager.sh download-model <url> <filename>
```

**Examples:**
```bash
# Download Qwen 2.5 0.5B model
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"

# Download Phi-3 Mini model  
./chat-manager.sh download-model \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" \
  "phi3-mini-4k-instruct-q4.gguf"

# Download to custom location
MODELS_DIR=/custom/path ./chat-manager.sh download-model <url> <filename>
```

**What it does:**
1. Creates models directory if needed
2. Uses wget or curl for download (whichever available)
3. Shows progress bar during download
4. Verifies download success
5. Reports final file size
6. Cleans up partial files on failure

---

## 🏥 Monitoring & Health

### `health` - Quick Health Check
Perform immediate health check of all services.

**Usage:**
```bash
./chat-manager.sh health
```

**Example Output:**
```bash
▶ Checking service health...
✓ llama.cpp server is healthy
✓ Flask application is healthy
```

**What it checks:**
- llama.cpp API responsiveness (GET /v1/models)
- Flask API responsiveness (GET /api/models)
- Service process status
- Port availability

---

### `test` - Comprehensive Installation Test
Run complete system test to verify installation integrity.

**Usage:**
```bash
./chat-manager.sh test
```

**Example Output:**
```bash
╔══════════════════════════════════════╗
║      Enhanced llama-chat Manager     ║
║     Dynamic Model Switching          ║
╚══════════════════════════════════════╝

Testing enhanced llama-chat installation...

▶ Checking directories...
✓ Directory exists: /home/user/llama-chat
✓ Directory exists: /home/user/llama-chat/models
✓ Directory exists: /home/user/llama-chat/logs

▶ Checking virtual environment...
✓ Virtual environment ready with required packages

▶ Checking llama.cpp installation...
✓ llama-server found at /usr/local/bin/llama-server
✓ llama-server is functional

▶ Checking models...
✓ Found 3 model file(s)
ℹ Smallest model for testing: qwen2.5-0.5b-instruct-q4_0.gguf

▶ Checking API availability...
✓ llama.cpp API accessible
✓ Flask API accessible

▶ Testing model switching capability...
✓ Multiple models available for switching

All critical tests passed! Enhanced installation looks good.

Next steps:
  • Start services: ./chat-manager.sh start
  • Check status: ./chat-manager.sh status
  • Switch models: ./chat-manager.sh switch-model <model-name>
  • Download models: ./chat-manager.sh download-model <url> <filename>
  • Monitor health: ./chat-manager.sh start-monitor
```

**Tests performed:**
1. Directory structure validation
2. Virtual environment setup
3. llama.cpp installation and functionality
4. Model file availability and format
5. API endpoint accessibility
6. Model switching capability
7. Configuration file validation

---

## 📝 Logs & Debugging

### `logs` - View Service Logs
Display recent log entries for specified services.

**Usage:**
```bash
./chat-manager.sh logs [service] [lines]
```

**Examples:**
```bash
# Show all recent logs
./chat-manager.sh logs

# Show last 50 lines of llama.cpp logs
./chat-manager.sh logs llamacpp 50

# Show last 25 lines of Flask logs
./chat-manager.sh logs flask 25

# Show monitor logs
./chat-manager.sh logs monitor

# Show last 100 lines of all logs
./chat-manager.sh logs all 100
```

**Available services:**
- `llamacpp` / `llama` / `server` - llama.cpp server logs
- `flask` / `web` / `app` - Flask application logs  
- `monitor` - Health monitoring logs
- `all` / `both` - All service logs

**Log locations:**
- llama.cpp: `$LOG_DIR/llamacpp.log`
- Flask: `$LOG_DIR/flask.log`
- Monitor: `$LOG_DIR/monitor.log`

---

### `follow` - Follow Logs in Real-time
Stream logs in real-time for debugging and monitoring.

**Usage:**
```bash
./chat-manager.sh follow [service]
```

**Examples:**
```bash
# Follow all logs
./chat-manager.sh follow

# Follow only llama.cpp logs
./chat-manager.sh follow llamacpp

# Follow Flask logs
./chat-manager.sh follow flask

# Follow monitor logs  
./chat-manager.sh follow monitor
```

**Keyboard shortcuts:**
- `Ctrl+C` - Stop following logs
- `Ctrl+Z` - Suspend (use `fg` to resume)

---

## 🧹 Maintenance & Utilities

### `cleanup` - Clean Logs and Temporary Files
Remove large log files and temporary data.

**Usage:**
```bash
./chat-manager.sh cleanup
```

**Examples:**
```bash
# Standard cleanup
./chat-manager.sh cleanup

# Cleanup with verbose output
DEBUG=true ./chat-manager.sh cleanup
```

**What it does:**
- Removes log files larger than 100MB
- Cleans temporary files
- Preserves recent log data
- Reports cleanup actions

---

### `force-cleanup` - Aggressive Process Cleanup
Forcefully kill all related processes and clean up stuck states.

**Usage:**
```bash
./chat-manager.sh force-cleanup
```

**Examples:**
```bash
# When services won't stop normally
./chat-manager.sh force-cleanup

# Before manual restart
./chat-manager.sh force-cleanup && ./chat-manager.sh start
```

**What it does:**
1. Kills processes using Flask and llama.cpp ports
2. Kills processes by name (Flask, llama-server)
3. Removes all PID files
4. Waits for process cleanup
5. Verifies ports are free
6. Reports any remaining issues

**⚠️ Warning:** This is aggressive - use only when normal stop fails.

---

### `setup-venv` - Setup Python Virtual Environment
Initialize or repair Python virtual environment.

**Usage:**
```bash
./chat-manager.sh setup-venv
```

**Examples:**
```bash
# Setup new environment
./chat-manager.sh setup-venv

# Recreate environment
rm -rf venv && ./chat-manager.sh setup-venv
```

**What it does:**
- Creates Python virtual environment
- Installs required packages from requirements.txt
- Validates package installation
- Reports setup status

**Aliases:** `setup-env`, `venv`

---

### `info` - System Information
Display comprehensive system and configuration information.

**Usage:**
```bash
./chat-manager.sh info
```

**Information displayed:**
- System specifications (CPU, RAM, OS)
- Python version and virtual environment status
- llama.cpp installation details
- Configuration file locations
- Model directory contents
- Port configurations
- Performance settings

---

### `check-port` - Check Port Usage
Check which processes are using specific ports.

**Usage:**
```bash
./chat-manager.sh check-port [port]
```

**Examples:**
```bash
# Check Flask port (default)
./chat-manager.sh check-port

# Check specific port
./chat-manager.sh check-port 8120

# Check both ports
./chat-manager.sh check-port 3333 && ./chat-manager.sh check-port 8120
```

---

## ⚙️ Configuration

### Environment Variables

The script respects these environment variables:

**Server Configuration:**
```bash
export LLAMACPP_PORT=8120          # llama.cpp server port
export LLAMACPP_HOST=127.0.0.1     # llama.cpp server host
export FLASK_PORT=3333             # Flask application port
export FLASK_HOST=127.0.0.1        # Flask application host
```

**Performance Settings:**
```bash
export CONTEXT_SIZE=4096           # Model context size
export GPU_LAYERS=0                # Number of GPU layers (0 = CPU only)
export THREADS=4                   # CPU threads for processing
export BATCH_SIZE=512              # Batch size for processing
```

**Model Management:**
```bash
export MODELS_DIR=./models         # Model directory path
export DEFAULT_MODEL="model.gguf"  # Default model filename
export MODEL_SWITCH_TIMEOUT=60     # Model switch timeout (seconds)
```

**Health Monitoring:**
```bash
export AUTO_RESTART_ON_CRASH=true  # Auto-restart crashed services
export HEALTH_CHECK_INTERVAL=30    # Health check interval (seconds)
```

**Performance Optimizations:**
```bash
export USE_MMAP=true               # Use memory mapping
export USE_MLOCK=false             # Use memory locking
```

### Configuration Files

**cm.conf** - Main configuration file:
```bash
# Server settings
LLAMACPP_PORT=8120
FLASK_PORT=3333

# Performance
GPU_LAYERS=0
CONTEXT_SIZE=4096

# Model management
DEFAULT_MODEL="qwen2.5-0.5b-instruct-q4_0.gguf"
MODEL_SWITCH_TIMEOUT=60

# Monitoring
AUTO_RESTART_ON_CRASH=true
HEALTH_CHECK_INTERVAL=30
```

---

## 🚀 Advanced Usage

### Chaining Commands
```bash
# Download, switch, and check status
./chat-manager.sh download-model <url> <file> && \
./chat-manager.sh switch-model <file> && \
./chat-manager.sh status

# Complete restart with cleanup
./chat-manager.sh stop && \
./chat-manager.sh force-cleanup && \
sleep 5 && \
./chat-manager.sh start

# Start with specific configuration
GPU_LAYERS=32 CONTEXT_SIZE=8192 ./chat-manager.sh start phi3-mini.gguf
```

### Scripting Integration
```bash
#!/bin/bash
# Example monitoring script

# Check if services are healthy
if ! ./chat-manager.sh health >/dev/null 2>&1; then
    echo "Services unhealthy, restarting..."
    ./chat-manager.sh restart
fi

# Switch to high-performance model during business hours
hour=$(date +%H)
if [ "$hour" -ge 9 ] && [ "$hour" -lt 17 ]; then
    ./chat-manager.sh switch-model phi3-mini-4k-instruct-q4.gguf
else
    ./chat-manager.sh switch-model qwen2.5-0.5b-instruct-q4_0.gguf
fi
```

### Performance Monitoring
```bash
# Monitor performance over time
while true; do
    echo "$(date): $(./chat-manager.sh health)"
    sleep 60
done

# Log model switches
./chat-manager.sh switch-model new-model.gguf 2>&1 | tee -a model-switches.log
```

---

## 📊 Exit Codes

The script returns specific exit codes for automation:

| Exit Code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | General error or command failure |
| `2` | Invalid command or missing parameters |
| `3` | Service startup failure |
| `4` | Port already in use |
| `5` | Model file not found |
| `6` | llama.cpp not installed |
| `7` | Virtual environment setup failure |

**Example usage in scripts:**
```bash
if ./chat-manager.sh start; then
    echo "Services started successfully"
else
    case $? in
        3) echo "Service startup failed" ;;
        4) echo "Port conflict detected" ;;
        6) echo "llama.cpp not installed" ;;
        *) echo "Unknown error occurred" ;;
    esac
fi
```

---

## 🔍 Common Patterns

### Daily Operations
```bash
# Morning startup
./chat-manager.sh start

# Check everything is working
./chat-manager.sh status

# Evening shutdown
./chat-manager.sh stop
```

### Development Workflow
```bash
# Start development environment
./chat-manager.sh start-llamacpp small-model.gguf
DEBUG=true ./chat-manager.sh start-flask

# Test model switching
./chat-manager.sh switch-model test-model.gguf

# Follow logs during development
./chat-manager.sh follow flask
```

### Production Deployment
```bash
# Start with monitoring
./chat-manager.sh start
./chat-manager.sh start-monitor

# Verify health
./chat-manager.sh test

# Setup log rotation
echo "0 2 * * * /path/to/chat-manager.sh cleanup" | crontab
```

### Troubleshooting Workflow
```bash
# When things go wrong
./chat-manager.sh status                    # Check what's running
./chat-manager.sh logs all 100             # Review recent logs
./chat-manager.sh force-cleanup             # Clean up if needed
./chat-manager.sh test                      # Verify installation
./chat-manager.sh start                     # Restart services
```

---

**💡 Pro Tips:**

1. **Use aliases** - Create shell aliases for frequently used commands
2. **Monitor logs** - Keep log files under control with regular cleanup
3. **Test first** - Always run `test` after major changes
4. **Environment variables** - Use cm.conf for persistent settings
5. **Health monitoring** - Enable automatic restart for production use
6. **Model organization** - Use descriptive model filenames
7. **Backup configurations** - Save working cm.conf files

**📚 Related Documentation:**
- [Main README](../README.md) - Project overview
- [Installation Guide](./install.md) - Setup instructions  
- [Configuration Guide](./config.md) - Detailed configuration
- [API Documentation](./api.md) - REST API reference
- [Troubleshooting](./troubleshooting.md) - Problem solving

---

*This documentation covers chat-manager.sh version 2.1+ with enhanced model switching and health monitoring capabilities.*