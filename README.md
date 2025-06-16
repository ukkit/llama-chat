# llama-chat 🦙

**Your lightweight, private, local AI chatbot powered by llama.cpp (no GPU required)**

A modern web interface for llama.cpp with markdown rendering, syntax highlighting, and intelligent conversation management. Chat with local LLMs through a sleek, GitHub-inspired interface.

![llama.cpp Chat Interface](https://img.shields.io/badge/Interface-Web%20Based-blue) ![Python](https://img.shields.io/badge/Python-3.8%2B-green) ![llama.cpp](https://img.shields.io/badge/Backend-llama.cpp-orange) ![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

- 🤖 **llama.cpp Integration** - Direct integration with llama.cpp server for optimal performance
- 💬 **Multiple Conversations** - Create, manage, and rename chat sessions
- 📚 **Persistent History** - SQLite database storage with search functionality
- 🚀 **Lightweight** - Minimal resource usage, runs on CPU-only systems
- 📝 **Full Markdown Rendering** - GitHub-flavored syntax with code highlighting
- 💻 **190+ Language Support** - Syntax highlighting for all major programming languages
- ⚡ **Performance Metrics** - Real-time response times, token tracking, and speed analytics
- 🔍 **Smart Search** - Full-text search across conversations and messages
- 📋 **Enhanced Copy Features** - Copy entire messages or individual code blocks
- 🎨 **Professional UI** - Dark theme with VS Code-inspired design

## 🚀 30-Second Quick Start

**For most users (auto-install):**

```bash
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
```

What happens?
- Installs Python/llama.cpp if missing
- Downloads recommended model (~400MB)
- Installs llama-chat with Flask frontend
- Starts both llama.cpp server and web interface

**Access at:** `http://localhost:3333`

<details>
<summary><b>🔧 Advanced Setup (Manual Install)</b></summary>

For detailed manual installation steps, see **[docs/install.md](./docs/install.md)**

```bash
# Prerequisites: Python 3.8+, llama.cpp, and at least one .gguf model
git clone https://github.com/ukkit/llama-chat.git
cd llama-chat
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
./chat-manager.sh start
```

</details>

## 📸 Screenshots

<details>
<summary><b>📷 App Screenshots</b></summary>

![llama-chat - Main Interface](./docs/assets/main-interface.png)
*Main chat interface with conversation management*

![llama-chat - Code Highlighting](./docs/assets/code-highlighting.png)
*Syntax highlighting with copy buttons for code blocks*

![llama-chat - Performance Metrics](./docs/assets/performance-metrics.png)
*Real-time performance tracking with token/second metrics*

![llama-chat - Search Feature](./docs/assets/search-feature.png)
*Full-text search across all conversations*

</details>

## 🏗️ Architecture

llama-chat uses a two-process architecture optimized for performance and reliability:

```
┌─────────────────┐    HTTP/REST API    ┌──────────────────┐
│   Flask Web UI  │ ←─────────────────→ │  llama.cpp       │
│   (Port 3333)   │                     │  Server          │
│                 │                     │  (Port 8120)     │
│   • Chat UI     │                     │  • Model Loading │
│   • Markdown    │                     │  • Text Gen      │
│   • Database    │                     │  • OpenAI API    │
│   • Search      │                     │  • Performance   │
└─────────────────┘                     └──────────────────┘
        │                                        │
        ├─ SQLite Database                      ├─ .gguf Models
        └─ Conversation History                 └─ CUDA/CPU Backend
```

### Key Components

- **Frontend**: Modern HTML5/CSS3/JavaScript with marked.js and highlight.js
- **Backend**: Flask REST API with SQLite database
- **AI Engine**: llama.cpp server with OpenAI-compatible API
- **Models**: Standard .gguf format models from Hugging Face

## 📊 Performance & Requirements

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | Dual-core 2GHz | Quad-core 3GHz+ |
| **RAM** | 4GB | 8GB+ |
| **Storage** | 2GB free | 10GB+ for multiple models |
| **OS** | Linux, macOS, Windows (WSL2) | Linux/macOS |
| **Python** | 3.8+ | 3.11+ |

### Model Performance (CPU-only)

| Model | Size | RAM Usage | Speed (CPU) | Quality |
|-------|------|-----------|-------------|---------|
| qwen2.5-0.5b-instruct | ~400MB | ~1GB | 15-30 tok/s | Good |
| phi3-mini-4k-instruct | ~2.3GB | ~3GB | 8-15 tok/s | Excellent |
| llama3.2-1b-instruct | ~1.3GB | ~2GB | 10-20 tok/s | Very Good |
| tinyllama | ~637MB | ~1GB | 20-40 tok/s | Basic |

*Performance varies by hardware. GPU acceleration available with CUDA/Metal.*

## 🛠️ Configuration

### Quick Configuration

llama-chat is designed to work out-of-the-box, but you can customize behavior via configuration files:

**Basic config.json:**
```json
{
  "model_options": {
    "temperature": 0.5,
    "num_predict": 2048,
    "num_ctx": 4096
  },
  "performance": {
    "context_history_limit": 10
  },
  "system_prompt": "You are a helpful AI assistant."
}
```

**Environment variables:**
```bash
export LLAMACPP_PORT=8120          # llama.cpp server port
export FLASK_PORT=3333             # Web interface port
export MODELS_DIR=./models         # Model directory
export GPU_LAYERS=32               # GPU acceleration (0 = CPU only)
```

### Configuration Files

| File | Purpose |
|------|---------|
| `config.json` | Model parameters, timeouts, system prompt |
| `llama-chat.conf` | Server settings, ports, paths |
| Environment variables | Runtime overrides |

See **[docs/config.md](./docs/config.md)** for complete configuration options.

## 🔧 Management Commands

llama-chat includes a comprehensive management script:

```bash
# Basic operations
./chat-manager.sh start              # Start both servers
./chat-manager.sh stop               # Stop both servers
./chat-manager.sh restart            # Restart both servers
./chat-manager.sh status             # Show service status

# Individual services
./chat-manager.sh start-llamacpp     # Start only llama.cpp server
./chat-manager.sh start-flask        # Start only Flask app

# Model management
./chat-manager.sh download-model <url> <filename>
./chat-manager.sh list-models        # Show available models

# Monitoring and troubleshooting
./chat-manager.sh logs               # View recent logs
./chat-manager.sh follow llamacpp    # Follow llama.cpp logs
./chat-manager.sh test               # Test installation
./chat-manager.sh info               # System information
```

## 🤖 Supported Models

llama-chat works with any .gguf format model. Here are some popular options:

### Recommended Starter Models

```bash
# Fast, lightweight (400MB)
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"

# High quality, balanced (2.3GB)
./chat-manager.sh download-model \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" \
  "phi3-mini-4k-instruct-q4.gguf"
```

### Model Categories

- **Ultra-fast**: tinyllama, qwen2.5:0.5b (good for testing)
- **Balanced**: phi3-mini, llama3.2:1b (daily use)
- **High-quality**: llama3.1:8b, qwen2.5:7b (when you have RAM)
- **Specialized**: codellama, mistral-nemo (coding, specific tasks)

See **[docs/models.md](./docs/models.md)** for complete model guide.

## 🎯 Use Cases

### 👩‍💻 **Development & Programming**
- **AI-assisted coding** with syntax-highlighted examples
- **Code documentation** with markdown formatting
- **API documentation** with structured formatting
- **Technical tutorials** with copy-paste code blocks

### 📚 **Research & Learning**
- **Interactive learning** with formatted educational content
- **Technical explanations** with mathematical notation
- **Study guides** with organized information hierarchy
- **Knowledge base building** with searchable conversations

### 💼 **Business & Content**
- **Technical documentation** with professional formatting
- **Meeting notes** with structured layouts
- **Process documentation** with clear formatting
- **Training materials** with rich content presentation

## 🔍 API & Integration

llama-chat provides a complete REST API for integration:

### Key Endpoints

```bash
# Get available models
GET /api/models

# Create conversation
POST /api/conversations
{"title": "New Chat", "model": "qwen2.5:0.5b"}

# Send message with performance metrics
POST /api/chat
{
  "conversation_id": 1,
  "message": "Hello",
  "model": "qwen2.5:0.5b"
}

# Response includes performance data:
{
  "response": "Hello! How can I help you?",
  "response_time_ms": 1250,
  "estimated_tokens": 12,
  "metrics": {...}
}

# Search conversations
GET /api/search?q=python

# Get conversation statistics
GET /api/stats/1
```

See **[docs/api.md](./docs/api.md)** for complete API documentation with examples.

## 🛡️ Privacy & Security

- **100% Local**: All processing happens on your machine
- **No Internet Required**: After initial setup, works completely offline
- **No Data Collection**: No telemetry, analytics, or data sharing
- **Private Conversations**: All chat history stored locally in SQLite
- **Open Source**: Full transparency, audit the code yourself

## 🔧 Troubleshooting

### Quick Fixes

| Issue | Solution |
|-------|----------|
| Port in use | `./chat-manager.sh start 8120` |
| No models | `./chat-manager.sh download-model <url> <file>` |
| Process stuck | `./chat-manager.sh force-stop` |
| Slow responses | Use smaller model or speed config |
| Memory issues | Reduce context size in config |

### Debug Mode

```bash
# Enable debug logging
DEBUG=true ./chat-manager.sh start

# View detailed logs
./chat-manager.sh logs both

# Test system health
./chat-manager.sh test
```

See **[docs/troubleshooting.md](./docs/troubleshooting.md)** for comprehensive troubleshooting.

## ✔️ Tested Platforms

| Platform | CPU | RAM | Status | Notes |
|----------|-----|-----|--------|-------|
| **Ubuntu 20.04+** | Any x86_64 | 4GB+ | ✅ Excellent | Primary development platform |
| **macOS 11+** | Intel/Apple Silicon | 8GB+ | ✅ Excellent | Native Metal acceleration |
| **Windows 11** | x86_64 | 8GB+ | ✅ Good | Via WSL2 recommended |
| **Raspberry Pi 4** | ARM Cortex-A72 | 8GB | ✅ Good | Use lightweight models |
| **Debian 11+** | x86_64 | 4GB+ | ✅ Excellent | Server deployments |

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](./docs/install.md) | Complete installation instructions |
| [Configuration Guide](./docs/config.md) | Detailed configuration options |
| [API Documentation](./docs/api.md) | REST API reference with examples |
| [Troubleshooting](./docs/troubleshooting.md) | Common issues and solutions |
| [Management Script](./docs/chat_manager_docs.md) | chat-manager.sh documentation |
| [Model Guide](./docs/models.md) | Model recommendations and setup |

## 🆕 Recent Updates

### **v2.0 - llama.cpp Integration**
- ✅ **Native llama.cpp support** with direct server integration
- ✅ **OpenAI-compatible API** for seamless model interaction
- ✅ **Performance metrics** tracking response times and token speeds
- ✅ **Enhanced model management** with automatic .gguf detection
- ✅ **Improved installation** with automatic dependency management
- ✅ **Better resource management** with optimized memory usage

### **v1.5 - Enhanced Features**
- ✅ **Full markdown rendering** with GitHub-flavored syntax
- ✅ **Syntax highlighting** for 190+ programming languages
- ✅ **Enhanced copy functionality** with code block copying
- ✅ **Search improvements** with performance metrics in results
- ✅ **Mobile optimization** for responsive design

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/awesome-feature`
3. **Make your changes** and test thoroughly
4. **Commit with clear messages**: `git commit -m "Add awesome feature"`
5. **Push to your fork**: `git push origin feature/awesome-feature`
6. **Create a Pull Request**

### Development Setup

```bash
git clone https://github.com/ukkit/llama-chat.git
cd llama-chat
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
./chat-manager.sh start
```

### Areas for Contribution

- 🔧 **Performance optimizations**
- 🎨 **UI/UX improvements**
- 📚 **Documentation enhancements**
- 🐛 **Bug fixes and testing**
- 🌍 **Internationalization**
- 📱 **Mobile app development**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[llama.cpp](https://github.com/ggml-org/llama.cpp)** - High-performance inference engine
- **[Flask](https://flask.palletsprojects.com/)** - Web framework
- **[marked.js](https://marked.js.org/)** - Markdown parser
- **[highlight.js](https://highlightjs.org/)** - Syntax highlighting
- **[Hugging Face](https://huggingface.co/)** - Model hosting and community

## 🌟 Support the Project

If you find llama-chat helpful:
- ⭐ **Star this repository**
- 🐛 **Report bugs** and suggest features
- 📖 **Improve documentation**
- 🔄 **Share with the community**

**Made with ❤️ for the local AI community**

---

**Ready to start chatting?**

```bash
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
```

Then open [http://localhost:3333](http://localhost:3333) and start your first conversation! 🦙