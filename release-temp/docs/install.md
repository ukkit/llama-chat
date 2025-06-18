# 📦 Complete Installation Guide

This guide provides both automatic and manual installation methods for llama-chat with llama.cpp.

## ⚡ Prerequisites for Fastest Setup

**For quickest installation (< 2 minutes), have these ready:**
- **Python 3.8+** with pip and venv modules
- **llama.cpp** with llama-server binary
- **At least one .gguf model** downloaded
- **git** (usually pre-installed on most systems)

**Quick prerequisite check:**
```bash
python3 --version          # Should show 3.8 or higher
python3 -m pip --version   # Should work without errors
python3 -m venv --help     # Should show venv help
llama-server --help        # Should show llama-server options
git --version              # Should show git version
```

**Installation time estimates:**
- **✅ With all prerequisites:** ~2 minutes
- **⏳ Missing some prerequisites:** ~5-10 minutes
- **📥 Fresh system (nothing installed):** ~10-20 minutes

---

## 🚀 Method 1: Automatic Installation (Recommended)

### One-Command Installation

**The easiest way to install llama-chat:**

```bash
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
```

**Alternative methods:**
```bash
# Using wget
wget -O- https://github.com/ukkit/llama-chat/raw/main/install.sh | sh

# Download and inspect first (recommended for security)
curl -O https://github.com/ukkit/llama-chat/raw/main/install.sh
cat install.sh  # Review the script
chmod +x install.sh
./install.sh
```

### What the Auto-Installer Does

**✅ Smart Detection & Installation:**
- **Checks for Python 3.8+** - Installs if missing or too old
- **Checks for llama.cpp** - Downloads and compiles if not found
- **Checks for git** - Installs if missing
- **Validates all tools** - Ensures everything works before proceeding

**✅ Efficient Setup:**
- **Downloads llama-chat** from GitHub (lightweight)
- **Creates virtual environment** (isolated Python environment)
- **Installs dependencies** (Flask, requests - minimal requirements)
- **Sets up permissions** (makes scripts executable)

**✅ Model Management:**
- **Checks existing models** - Uses what you already have
- **Recommends qwen2.5-0.5b-instruct** (~400MB, fastest)
- **Provides alternatives** if download fails
- **Skips download** if you prefer to install models later

**✅ Service Launch:**
- **Starts llama.cpp server** on available port (default: 8080)
- **Starts Flask web interface** on available port (default: 3000)
- **Provides access URL** and management commands
- **Shows next steps** and usage instructions

### Installation Time Breakdown

**With Prerequisites Present:**
```
Downloading llama-chat       : 10-30 seconds
Setting up environment       : 30-60 seconds
Installing Python packages   : 30-60 seconds
Starting applications        : 5-10 seconds
Total                        : ~2 minutes
```

**Installing Prerequisites:**
```
Installing Python (if needed): 2-5 minutes
Installing llama.cpp (if needed): 3-8 minutes (compilation)
Downloading model (if needed) : 2-10 minutes (depends on model size)
Setting up llama-chat        : 2 minutes
Total                        : 7-25 minutes
```

### Expected Output

**With Prerequisites:**
```
╔══════════════════════════════════════╗
║      llama-chat 🦙 (llama.cpp)       ║
║      Non-Interactive Installer       ║
╚══════════════════════════════════════╝

✓ Python 3.11.2 found at /usr/bin/python3
✓ llama-server found at /usr/local/bin/llama-server
✓ Found existing models: qwen2.5-0.5b-instruct-q4_0.gguf
✓ llama-chat downloaded successfully
✓ Virtual environment created
✓ Dependencies installed successfully
✓ llama.cpp server started on port 8080
✓ llama-chat started successfully!

🎉 Installation Complete! 🎉
Access at: http://localhost:3000
```

**Without Prerequisites:**
```
╔══════════════════════════════════════╗
║      llama-chat 🦙 (llama.cpp)       ║
║      Non-Interactive Installer       ║
╚══════════════════════════════════════╝

⚠ Python 3.8+ not found, installing...
✓ Python 3.11.2 installed successfully
⚠ llama.cpp not found, compiling from source...
✓ llama.cpp compiled and installed successfully
⚠ No models found, downloading qwen2.5-0.5b-instruct...
✓ Model downloaded successfully (~400MB)
✓ llama-chat downloaded successfully
✓ Virtual environment created
✓ Dependencies installed successfully
✓ llama.cpp server started on port 8080
✓ llama-chat started successfully!

🎉 Installation Complete! 🎉
Access at: http://localhost:3000
```

### Post-Installation

After automatic installation, you can manage the services with:

```bash
cd ~/llama-chat
source venv/bin/activate
./chat-manager.sh status    # Check status
./chat-manager.sh stop      # Stop services
./chat-manager.sh restart   # Restart services
./chat-manager.sh logs      # View logs
```

---

## 🔧 Method 2: Manual Installation

### Prerequisites Installation

**If you want the fastest setup, install these first:**

#### Ubuntu/Debian
```bash
# Install Python 3.8+ with essential modules
sudo apt update
sudo apt install python3 python3-pip python3-venv git curl build-essential cmake

# Verify Python version (should be 3.8+)
python3 --version

# Install llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo cp bin/llama-server /usr/local/bin/
cd ../..

# Download a model for immediate use
mkdir -p models
curl -L -o models/qwen2.5-0.5b-instruct-q4_0.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"
```

#### CentOS/RHEL/Fedora
```bash
# Install Python 3.8+ and tools
sudo dnf install python3 python3-pip git curl cmake gcc-c++ make
# OR for older versions
sudo yum install python3 python3-pip git curl cmake gcc-c++ make

# Install llama.cpp (same as Ubuntu)
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo cp bin/llama-server /usr/local/bin/
cd ../..

# Download a model
mkdir -p models
curl -L -o models/qwen2.5-0.5b-instruct-q4_0.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"
```

#### macOS
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python and dependencies
brew install python3 git cmake

# Install llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(sysctl -n hw.ncpu)
cp bin/llama-server /usr/local/bin/
cd ../..

# Download a model
mkdir -p models
curl -L -o models/qwen2.5-0.5b-instruct-q4_0.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"
```

#### Windows (WSL2 recommended)
```bash
# Enable WSL2 and install Ubuntu
# Then follow Ubuntu instructions above
```

### Quick Setup (With Prerequisites Ready)

**Time estimate: ~2 minutes**

```bash
# 1. Download llama-chat
git clone https://github.com/ukkit/llama-chat.git
cd llama-chat

# 2. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Make script executable and start
chmod +x chat-manager.sh
./chat-manager.sh start

# 5. Access the application
# Open browser to http://localhost:3000
```

### Complete Manual Installation (Fresh System)

**Time estimate: ~10-20 minutes**

#### Step 1: Install Python 3.8+

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv git curl build-essential cmake
python3 --version  # Verify 3.8+
```

**CentOS/RHEL:**
```bash
sudo dnf install python3 python3-pip git curl cmake gcc-c++ make
python3 --version  # Verify 3.8+
```

**macOS:**
```bash
brew install python3 git cmake
python3 --version  # Verify 3.8+
```

#### Step 2: Install llama.cpp

```bash
# Clone and build llama.cpp
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build

# Configure with GPU support (optional)
# For CUDA:
# cmake -DCMAKE_BUILD_TYPE=Release -DLLAMA_CUDA=ON ..
# For Metal (macOS):
# cmake -DCMAKE_BUILD_TYPE=Release -DLLAMA_METAL=ON ..
# For CPU only:
cmake -DCMAKE_BUILD_TYPE=Release ..

# Build (adjust -j based on your CPU cores)
make -j$(nproc)

# Install llama-server binary
sudo cp bin/llama-server /usr/local/bin/
# OR for user install:
# mkdir -p ~/.local/bin && cp bin/llama-server ~/.local/bin/

# Verify installation
llama-server --help

cd ../..  # Return to working directory
```

#### Step 3: Download Models

```bash
# Create models directory
mkdir -p models

# Download recommended starter model (~400MB)
echo "Downloading qwen2.5-0.5b-instruct model..."
curl -L --progress-bar -o models/qwen2.5-0.5b-instruct-q4_0.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"

# Verify download
ls -lh models/
```

#### Step 4: Install llama-chat

```bash
# Clone repository
git clone https://github.com/ukkit/llama-chat.git
cd llama-chat

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Make scripts executable
chmod +x chat-manager.sh

# Start application
./chat-manager.sh start
```

#### Step 5: Verify Installation

```bash
# Check if services are running
./chat-manager.sh status

# Test llama.cpp server API
curl http://localhost:8080/health

# Test Flask app
curl http://localhost:3000/api/models

# Open in browser
# http://localhost:3000
```

---

## ⚡ Speed Optimization Tips

### For 2-Minute Setup
```bash
# 1. Pre-install everything first
sudo apt update && sudo apt install python3 python3-pip python3-venv git cmake build-essential
# Compile llama.cpp (5-8 minutes)
# Download model (2-5 minutes depending on size)

# 2. Then run installer (will be super fast)
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
```

### Model Download Time Estimates
| Model | Size | Download Time* | Performance |
|-------|------|----------------|-------------|
| qwen2.5-0.5b-instruct | ~400MB | 1-3 minutes | Fast, good quality |
| tinyllama | ~637MB | 2-5 minutes | Ultra lightweight |
| phi3-mini-4k-instruct | ~2.3GB | 5-15 minutes | Excellent balance |
| llama3.2-1b-instruct | ~1.3GB | 3-8 minutes | Better quality |

*Depends on internet speed

### Internet Connection Impact
- **Fast connection (50+ Mbps):** Full setup in 5-10 minutes
- **Medium connection (10-50 Mbps):** Full setup in 10-15 minutes
- **Slow connection (<10 Mbps):** Consider pre-downloading models

### Hardware Performance Tips
```bash
# For systems with limited resources
# Use smallest model and speed config
cp docs/speed_config.json config.json

# For powerful systems with GPU
# Edit llama-chat.conf:
GPU_LAYERS=32  # Use GPU acceleration
```

---

## 🔍 Troubleshooting Installation

### Common Issues and Solutions

#### Python Issues
```bash
# Python command not found
sudo apt install python3  # Ubuntu/Debian
brew install python3      # macOS

# pip not found
sudo apt install python3-pip  # Ubuntu/Debian

# venv module not found
sudo apt install python3-venv  # Ubuntu/Debian
```

#### llama.cpp Issues
```bash
# llama-server command not found
export PATH="/usr/local/bin:$PATH"
# OR check if it's in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Compilation errors
sudo apt install build-essential cmake  # Ubuntu/Debian
brew install cmake                       # macOS

# CUDA compilation issues (if using GPU)
export CUDA_PATH=/usr/local/cuda
cmake -DCMAKE_BUILD_TYPE=Release -DLLAMA_CUDA=ON ..
```

#### Permission Issues
```bash
# Script not executable
chmod +x chat-manager.sh install.sh

# Directory permissions
sudo chown -R $USER:$USER ~/llama-chat
```

#### Port Issues
```bash
# Port already in use
./chat-manager.sh start-llamacpp 8081  # Use different port
./chat-manager.sh start-flask 3001     # Use different port
sudo lsof -i :8080  # Check what's using port 8080
```

#### Memory Issues
```bash
# For low-memory systems, use smaller models
# Download tinyllama instead:
curl -L -o models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf \
  "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_0.gguf"

# Use speed config for less memory
cp docs/speed_config.json config.json
./chat-manager.sh restart
```

### Debug Mode

```bash
# Enable debug logging
export DEBUG=true
./chat-manager.sh start

# View detailed logs
./chat-manager.sh logs both
tail -f logs/llamacpp.log
tail -f logs/flask.log
```

### Reinstall/Reset

```bash
# Complete reinstall
rm -rf ~/llama-chat
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash

# Reset only database
./chat-manager.sh stop
rm -f data/llama-chat.db
./chat-manager.sh start

# Reset only virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## 📋 Verification Checklist

After installation, verify everything works:

- [ ] **Python**: `python3 --version` shows 3.8+
- [ ] **llama.cpp**: `llama-server --help` shows options
- [ ] **Models**: `.gguf` files exist in models directory
- [ ] **Services**: `./chat-manager.sh status` shows both running
- [ ] **Web Interface**: http://localhost:3000 loads
- [ ] **API**: `curl http://localhost:8080/health` returns OK
- [ ] **Chat**: Can select model and send test message

---

## 🔄 Updates and Maintenance

### Update llama-chat

```bash
cd ~/llama-chat
./chat-manager.sh stop
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
./chat-manager.sh start
```

### Update llama.cpp

```bash
# Update to latest llama.cpp
cd ~/llama.cpp  # Or wherever you compiled it
git pull origin master
cd build
make -j$(nproc)
sudo cp bin/llama-server /usr/local/bin/
```

### Download New Models

```bash
cd ~/llama-chat
./chat-manager.sh download-model \
  "https://huggingface.co/model-url/model.gguf" \
  "model.gguf"
```

### Backup Data

```bash
# Backup conversation database
cp data/llama-chat.db ~/llama-chat-backup.db

# Backup configuration
cp config.json ~/config-backup.json
cp llama-chat.conf ~/llama-chat-conf-backup
```

---

## 🆘 Getting Help

If you encounter issues:

1. **Check the troubleshooting section above**
2. **View logs**: `./chat-manager.sh logs both`
3. **Check GitHub Issues**: https://github.com/ukkit/llama-chat/issues
4. **Enable debug mode**: `DEBUG=true ./chat-manager.sh start`
5. **Verify system requirements** are met

**Community Support:**
- GitHub Issues: Report bugs and feature requests
- Discussions: Share tips and configurations
- Documentation: Check docs/ folder for detailed guides

**System Information for Bug Reports:**
```bash
# Collect system info for bug reports
echo "OS: $(uname -a)"
echo "Python: $(python3 --version)"
echo "llama.cpp: $(llama-server --version 2>/dev/null || echo 'not found')"
echo "Models: $(ls -la models/ 2>/dev/null || echo 'no models directory')"
./chat-manager.sh status
```

Happy chatting with llama.cpp! 🦙