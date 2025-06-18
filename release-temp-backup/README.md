# llama-chat 🦙

**Your lightweight, private, local AI chatbot powered by llama.cpp (no GPU required)**

A modern web interface for llama.cpp with markdown rendering, syntax highlighting, and intelligent conversation management. Chat with local LLMs through a sleek, GitHub-inspired interface.

![llama.cpp Chat Interface](https://img.shields.io/badge/Interface-Web%20Based-blue) ![Python](https://img.shields.io/badge/Python-3.8%2B-green) ![llama.cpp](https://img.shields.io/badge/Backend-llama.cpp-orange) ![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

- 🤖 **llama.cpp Integration** - Direct integration with llama.cpp server for optimal performance
- 🔄 **Dynamic Model Switching** - Switch between models without restarting services
- 💬 **Multiple Conversations** - Create, manage, and rename chat sessions
- 📚 **Persistent History** - SQLite database storage with search functionality
- 🚀 **Lightweight** - Minimal resource usage, runs on CPU-only systems
- 📝 **Full Markdown Rendering** - GitHub-flavored syntax with code highlighting
- ⚡ **Performance Metrics** - Real-time response times, token tracking, and speed analytics
- 🏥 **Health Monitoring** - Automatic service monitoring and restart capabilities

## 🚀 Quick Start

## Prerequisites

⚠️ Before installing llama-chat, you need to have **llama.cpp** installed on your system ⚠️

**Install llama.cpp:**
```bash
# Option 1: Build via llama_cpp_setup.sh ((recommended)
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/llama_cpp_setup.sh | bash
```
<details><summary><b>Other installation options</b></summary>

```bash
# Option 2:Build from source
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build
cmake --build build --config Release

# Option 3: Install via package manager (if available)
# Ubuntu/Debian:
# apt install llama.cpp

# macOS:
# brew install llama.cpp
```
</details>


**⚠️ Make sure llama-server is in your PATH ⚠️**

```bash
which llama-server  # Should show the path to llama-server
```

## 30-Second Quick Start

**For most users (auto-install):**

```bash
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
```

What the install script does:
- ✅ Sets up Python virtual environment
- ✅ Downloads recommended model (~400MB)
- ✅ Installs llama-chat with Flask frontend
- ✅ Creates configuration files
- ✅ Starts both llama.cpp server and web interface

**Access at:** `http://localhost:3333`

<details>
<summary><b>🔧 Manual Installation</b></summary>

For detailed manual installation steps:

```bash
# Prerequisites: Python 3.8+, llama.cpp installed, and at least one .gguf model
git clone https://github.com/ukkit/llama-chat.git
cd llama-chat
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Download a model (optional - you can add your own)
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"

# Start services
./chat-manager.sh start
```

</details>

## 📸 Screenshots

<details>
<summary><b>📷 App Screenshots</b></summary>

![llama-chat - Main Interface](./docs/assets/main_interface.png)
*Main interface*

![llama-chat - Chat Interface](./docs/assets/chat_interface.png)
*Chat Interface*

![llama-chat - Model Selection](./docs/assets/model_selection.png)
*Select Models from Dropdown*

![llama-chat - Switch Model](./docs/assets/switching_models.png)
*Model Switch*

![llama-chat - Switch Model via Chat Selection](./docs/assets/switch_via_chat_selection.png)
*Switch Model by Selecting existin Chat*

![llama-chat - Model Switched](./docs/assets/model_switched.png)
*Model Switching complete*

![llama-chat - Markdown Support](./docs/assets/markdown_support.png)
*Full Markdown rendering*

</details>

### Configuration Files

| File | Purpose |
|------|---------|
| `cm.conf` | Main chat-manager configuration (ports, performance, model settings) |
| `config.json` | Model parameters, timeouts, system prompt |
| `docs/detailed_cm.conf` | Config file with more configuration options for llama-chat and llama.cpp server |

See **[docs/config.md](./docs/config.md)** for complete configuration options.

## 🔧 Enhanced Management Commands

llama-chat includes a comprehensive management script with enhanced features:

### Core Operations
```bash
# Basic operations
./chat-manager.sh start              # Start all services (llama.cpp + Flask + monitor)
./chat-manager.sh stop               # Stop all services
./chat-manager.sh restart            # Restart all services
./chat-manager.sh status             # Show detailed service status and health
```

See **[docs/chat-manager.md](./docs/chat-manager.md)** for detailed operations

## 🤖 Supported Models

llama-chat works with any .gguf format model. Here are some popular options:

### Recommended Starter Models

```bash
# Fast, lightweight (400MB) - Great for testing
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"
```

```bash
# Compact, good performance (1.3GB)
./chat-manager.sh download-model \
  "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf" \
  "llama3.2-1b-instruct-q4.gguf"
```

### Model Categories

- **Ultra-fast**: tinyllama, qwen2.5:0.5b (good for testing)
- **Balanced**: phi3-mini, llama3.2:1b (daily use)
- **High-quality**: llama3.1:8b, qwen2.5:7b (when you have RAM)
- **Specialized**: codellama, mistral-nemo (coding, specific tasks)

### Dynamic Model Switching

Switch between models without restarting services:

```bash
# Switch to a different model
./chat-manager.sh switch-model phi3-mini-4k-instruct-q4.gguf

# Check current model
./chat-manager.sh status

# List available models
./chat-manager.sh list-models
```

## 🔧 Need Help

| Issue | Solution |
|-------|----------|
| **llama.cpp not found** | Install llama.cpp and ensure `llama-server` is in PATH |
| **Port in use** | `./chat-manager.sh force-cleanup` |
| **No models** | `./chat-manager.sh download-model <url> <file>` |
| **Process stuck** | `./chat-manager.sh force-cleanup` |
| **Slow responses** | Use smaller model or adjust GPU_LAYERS |
| **Memory issues** | Reduce context size in cm.conf |
| **Model switching fails** | Check model file exists: `./chat-manager.sh list-models` |
| **Services won't start** | Check health: `./chat-manager.sh test` |


### Common Installation Issues

| Problem | Cause | Solution |
|---------|-------|---------|
| **llama-server not found** | llama.cpp not installed | Install llama.cpp from source or package manager |
| **Permission denied** | Executable permissions missing | `chmod +x chat-manager.sh` |
| **Port conflicts** | Services already running | `./chat-manager.sh force-cleanup` |
| **Python module errors** | Virtual environment issues | Re-run setup: `./chat-manager.sh setup-venv` |
| **Model loading fails** | Corrupted or wrong format | Re-download model |

See **[docs/troubleshooting.md](./docs/troubleshooting.md)** for comprehensive troubleshooting.

## ✔️ Tested Platforms

| Platform | CPU | RAM | llama.cpp | Status | Notes |
|----------|-----|-----|-----------|--------|-------|
| **Ubuntu 20.04+** | x86_64 | 8GB+ | Source/Package | ✅ Excellent | Primary development platform |
| **Windows 11** | x86_64 | 8GB+ | WSL2/Source | ✅ Good | WSL2 recommended |
| **Debian 12+** | x86_64 | 8GB+ | Source/Package | ✅ Excellent | Server deployments |

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](./docs/install.md) | Complete installation instructions |
| [Configuration Guide](./docs/config.md) | Detailed configuration options |
| [API Documentation](./docs/api.md) | REST API reference with examples |
| [Troubleshooting](./docs/troubleshooting.md) | Common issues and solutions |
| [Management Script](./docs/chat-manager.md) | chat-manager.sh documentation |
| [Models](./docs/models.md) | Model recommendations and setup |

## 🙏 Acknowledgments

- **[llama.cpp](https://github.com/ggml-org/llama.cpp)** - High-performance inference engine
- **[Flask](https://flask.palletsprojects.com/)** - Web framework
- **[marked.js](https://marked.js.org/)** - Markdown parser
- **[highlight.js](https://highlightjs.org/)** - Syntax highlighting
- **[Hugging Face](https://huggingface.co/)** - Model hosting and community

**Made with ❤️ for the AI community**

> ⭐ Star this project if you find it helpful!

---

MIT License - see [LICENSE](LICENSE) file.