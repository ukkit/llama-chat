# 🔧 Troubleshooting Guide - llama-chat

Complete troubleshooting guide for llama-chat installation, configuration, and runtime issues with llama.cpp backend.

## 📋 Table of Contents

- [Quick Fixes](#-quick-fixes)
- [Installation Issues](#-installation-issues)
- [Runtime Issues](#-runtime-issues)
- [Performance Issues](#-performance-issues)
- [Configuration Issues](#-configuration-issues)
- [llama.cpp Issues](#-llamacpp-issues)
- [Model Management Issues](#-model-management-issues)
- [Network Issues](#-network-issues)
- [Database Issues](#-database-issues)
- [Debug Mode](#-debug-mode)
- [System Information](#-system-information)
- [Getting Help](#-getting-help)

---

## 🚀 Quick Fixes

### Most Common Issues

| Issue | Quick Fix |
|-------|-----------|
| **llama-server not found** | Install llama.cpp and ensure it's in PATH |
| **Port in use** | `./chat-manager.sh force-cleanup` |
| **Process won't stop** | `./chat-manager.sh force-cleanup` |
| **No models available** | `./chat-manager.sh download-model <url> <filename>` |
| **Permission denied** | `chmod +x chat-manager.sh` |
| **Model won't switch** | `./chat-manager.sh list-models` then check file exists |
| **Services crash** | `./chat-manager.sh test` to check installation |
| **Slow responses** | Use smaller model: `./chat-manager.sh switch-model qwen2.5-0.5b-instruct-q4_0.gguf` |

### Emergency Reset

```bash
# Stop all services
./chat-manager.sh force-cleanup

# Reset virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Reset database (loses chat history)
rm -f data/llama-chat.db

# Reset configuration
rm -f cm.conf config.json

# Start fresh
./chat-manager.sh start
```

---

## 🛠️ Installation Issues

### llama.cpp Installation Problems

#### llama-server Not Found
```bash
# Check if llama-server is installed
which llama-server
llama-server --help

# Install llama.cpp from source (recommended)
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make clean
make -j$(nproc)

# Add to PATH
echo 'export PATH="$PATH:/path/to/llama.cpp"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
llama-server --version
```

#### Build Issues on Different Systems

**Ubuntu/Debian:**
```bash
# Install build dependencies
sudo apt update
sudo apt install build-essential cmake git

# For GPU support (optional)
sudo apt install nvidia-cuda-toolkit  # NVIDIA
sudo apt install rocm-dev             # AMD

# Build with GPU support
make LLAMA_CUDA=1  # NVIDIA
make LLAMA_HIPBLAS=1  # AMD
```

**macOS:**
```bash
# Install Xcode command line tools
xcode-select --install

# Install dependencies
brew install cmake

# Build with Metal support (Apple Silicon)
make LLAMA_METAL=1
```

**Windows (WSL2):**
```bash
# Use WSL2 Ubuntu and follow Ubuntu instructions
# Or use pre-built binaries from releases
wget https://github.com/ggerganov/llama.cpp/releases/latest/download/llama-cpp-linux-x64.zip
unzip llama-cpp-linux-x64.zip
sudo cp llama-server /usr/local/bin/
```

### Auto-Installer Problems

#### Installation Script Fails
```bash
# Check prerequisites first
python3 --version  # Should be 3.8+
which git
which curl || which wget

# Run with debug output
bash -x install.sh 2>&1 | tee install-debug.log

# Manual troubleshooting
curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

#### Python/Virtual Environment Issues
```bash
# Python not found or too old
sudo apt update && sudo apt install python3 python3-pip python3-venv  # Ubuntu/Debian
brew install python3  # macOS

# venv module missing
sudo apt install python3-venv  # Ubuntu/Debian
python3 -m pip install virtualenv  # Alternative

# pip issues
python3 -m ensurepip --default-pip
python3 -m pip install --upgrade pip

# Virtual environment creation fails
rm -rf venv
python3 -m venv venv --clear
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

---

## 🏃 Runtime Issues

### Services Won't Start

#### Port Conflicts
```bash
# Check what's using llama.cpp port (8120)
sudo lsof -i :8120
netstat -tulpn | grep 8120

# Check what's using Flask port (3333)
sudo lsof -i :3333
netstat -tulpn | grep 3333

# Kill processes using ports
sudo kill -9 $(lsof -ti :8120)
sudo kill -9 $(lsof -ti :3333)

# Use different ports
LLAMACPP_PORT=8121 FLASK_PORT=3334 ./chat-manager.sh start
```

#### llama-server Startup Issues
```bash
# Check if llama-server can start manually
llama-server --help

# Test with minimal parameters
llama-server --model models/your-model.gguf --port 8120

# Common startup failures:
# 1. Model file not found
ls -la models/
./chat-manager.sh list-models

# 2. Insufficient memory
free -h
# Use smaller model or reduce context size

# 3. Permission issues
chmod 644 models/*.gguf
```

#### Flask Application Issues
```bash
# Check if Flask can start manually
source venv/bin/activate
python app.py

# Common Flask issues:
# 1. Virtual environment not activated
source venv/bin/activate
which python  # Should point to venv

# 2. Missing dependencies
pip install -r requirements.txt --force-reinstall

# 3. Import errors
python -c "import flask, requests, sqlite3"

# 4. Database permissions
mkdir -p data
chmod 755 data
touch data/llama-chat.db
chmod 644 data/llama-chat.db
```

### Service Crashes

#### llama.cpp Server Crashes
```bash
# Check llama.cpp logs
./chat-manager.sh logs llamacpp 50

# Common crash causes:
# 1. Out of memory
free -h
# Solution: Use smaller model or reduce context size in cm.conf

# 2. Corrupted model file
md5sum models/your-model.gguf
# Re-download model if corrupted

# 3. Invalid parameters
# Check cm.conf for valid values:
# CONTEXT_SIZE (reasonable: 1024-4096)
# GPU_LAYERS (0 for CPU-only)
# THREADS (should match CPU cores)
```

#### Flask Application Crashes
```bash
# Check Flask logs
./chat-manager.sh logs flask 50

# Run Flask in foreground for debugging
source venv/bin/activate
DEBUG=true python app.py

# Common crash causes:
# 1. Database corruption
sqlite3 data/llama-chat.db "PRAGMA integrity_check;"

# 2. Configuration errors
python -m json.tool config.json

# 3. Memory exhaustion
ps aux | grep python
# Monitor memory usage
```

#### Health Monitor Issues
```bash
# Check monitor logs
./chat-manager.sh logs monitor 20

# Monitor settings in cm.conf
# AUTO_RESTART_ON_CRASH=true
# HEALTH_CHECK_INTERVAL=30

# Restart monitor manually
./chat-manager.sh stop-monitor
./chat-manager.sh start-monitor
```

---

## ⚡ Performance Issues

### Slow Response Times

#### Model-Related Performance
```bash
# Check current model
./chat-manager.sh status

# Switch to faster model
./chat-manager.sh switch-model qwen2.5-0.5b-instruct-q4_0.gguf

# Download lightweight models
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"

# Performance comparison by model size:
# qwen2.5-0.5b (~400MB): 15-30 tok/s on CPU
# tinyllama (~637MB): 12-25 tok/s on CPU  
# llama3.2-1b (~1.3GB): 8-15 tok/s on CPU
# phi3-mini (~2.3GB): 3-8 tok/s on CPU
```

#### Configuration Optimization
```bash
# Optimize cm.conf for speed:
cat > cm.conf << 'EOF'
# Speed-optimized configuration
CONTEXT_SIZE=1024           # Smaller context for speed
BATCH_SIZE=512             # Larger batches for throughput
THREADS=4                  # Match your CPU cores
GPU_LAYERS=0               # CPU-only (adjust if you have GPU)
USE_MMAP=true             # Memory optimization
USE_MLOCK=false           # Let OS manage memory
EOF

# Restart with new config
./chat-manager.sh restart
```

#### System Resource Optimization
```bash
# Check CPU usage
top -p $(pgrep llama-server)
htop

# Check memory pressure
free -h
cat /proc/meminfo | grep Available

# Optimize system for AI workloads
# Close unnecessary applications
# Ensure adequate cooling
# Use SSD storage for models

# Check disk I/O (slow storage affects model loading)
iostat -x 1 5
```

### High Memory Usage

#### Memory Optimization Strategies
```bash
# Monitor memory usage
watch -n 1 'free -h && ps aux | grep -E "(llama-server|python)" | grep -v grep'

# Reduce memory usage in cm.conf:
CONTEXT_SIZE=1024          # Reduce from default 4096
BATCH_SIZE=256            # Reduce from default 512
USE_MMAP=true             # Essential for large models
USE_MLOCK=false           # Don't lock memory

# Use quantized models (smaller but similar quality)
# Q4_0: 4-bit quantization (good balance)
# Q4_K_M: 4-bit with improved quality
# Q5_0: 5-bit quantization (better quality, larger)

# Emergency memory reduction
echo 3 | sudo tee /proc/sys/vm/drop_caches  # Clear system caches
```

#### Model Size vs. Memory Usage
```bash
# Check model sizes
./chat-manager.sh list-models

# Memory usage estimates:
# Model Size + Context Memory ≈ Total RAM needed
# qwen2.5-0.5b (400MB) + 2048 context ≈ 1.5GB total
# llama3.2-1b (1.3GB) + 2048 context ≈ 2.5GB total
# phi3-mini (2.3GB) + 2048 context ≈ 3.5GB total

# For 8GB RAM systems, stick to models < 3GB
# For 4GB RAM systems, stick to models < 1GB
```

---

## ⚙️ Configuration Issues

### cm.conf Configuration Problems

#### Invalid Configuration Values
```bash
# Check current configuration
./chat-manager.sh status

# Validate cm.conf syntax
source cm.conf && echo "Syntax OK" || echo "Syntax ERROR"

# Common configuration errors and fixes:

# 1. Invalid port numbers
LLAMACPP_PORT=8120         # Valid range: 1024-65535
FLASK_PORT=3333           # Must be different from LLAMACPP_PORT

# 2. Invalid thread count
THREADS=$(nproc)          # Use number of CPU cores
# Or set manually: THREADS=4

# 3. Invalid context size
CONTEXT_SIZE=2048         # Valid range: 256-32768
# Higher = more memory usage

# 4. Invalid GPU layers (for CPU-only systems)
GPU_LAYERS=0              # Set to 0 for CPU-only

# 5. Invalid timeout values
MODEL_SWITCH_TIMEOUT=60   # Seconds, reasonable range: 30-300
HEALTH_CHECK_INTERVAL=30  # Seconds, reasonable range: 15-120
```

#### Configuration File Examples
```bash
# Minimal cm.conf for testing
cat > cm.conf << 'EOF'
LLAMACPP_PORT=8120
FLASK_PORT=3333
CONTEXT_SIZE=1024
GPU_LAYERS=0
THREADS=4
EOF

# High-performance cm.conf (for powerful systems)
cat > cm.conf << 'EOF'
LLAMACPP_PORT=8120
FLASK_PORT=3333
CONTEXT_SIZE=4096
BATCH_SIZE=512
GPU_LAYERS=32              # Adjust based on your GPU
THREADS=8                  # Adjust based on your CPU
USE_MMAP=true
USE_MLOCK=true
MODEL_SWITCH_TIMEOUT=90
AUTO_RESTART_ON_CRASH=true
HEALTH_CHECK_INTERVAL=30
EOF

# Low-resource cm.conf (for limited systems)
cat > cm.conf << 'EOF'
LLAMACPP_PORT=8120
FLASK_PORT=3333
CONTEXT_SIZE=1024
BATCH_SIZE=128
GPU_LAYERS=0
THREADS=2
USE_MMAP=true
USE_MLOCK=false
MODEL_SWITCH_TIMEOUT=120
AUTO_RESTART_ON_CRASH=true
HEALTH_CHECK_INTERVAL=60
EOF
```

### JSON Configuration Issues

#### config.json Syntax Errors
```bash
# Validate JSON syntax
python -m json.tool config.json

# Common JSON errors:
# 1. Trailing commas
# 2. Missing quotes
# 3. Invalid escape characters

# Reset to default config.json
cat > config.json << 'EOF'
{
  "model_options": {
    "temperature": 0.7,
    "top_p": 0.9,
    "top_k": 40,
    "num_predict": 2048
  },
  "performance": {
    "context_history_limit": 10
  },
  "system_prompt": "You are a helpful AI assistant."
}
EOF
```

---

## 🦙 llama.cpp Issues

### Server Connection Problems

#### llama.cpp Server Not Responding
```bash
# Test llama.cpp server directly
curl http://localhost:8120/v1/models
curl http://localhost:8120/health

# Check if server is running
ps aux | grep llama-server
./chat-manager.sh status

# Common connection issues:
# 1. Server not started
./chat-manager.sh start-llamacpp

# 2. Wrong port
netstat -tulpn | grep 8120

# 3. Firewall blocking connection
sudo ufw allow 8120  # Ubuntu
sudo firewall-cmd --add-port=8120/tcp  # CentOS/RHEL

# 4. Server crashed - check logs
./chat-manager.sh logs llamacpp 50
```

#### API Compatibility Issues
```bash
# Test OpenAI-compatible API endpoints
curl http://localhost:8120/v1/models
curl http://localhost:8120/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello", "max_tokens": 50}'

# If API responses are unexpected:
# 1. Check llama.cpp version
llama-server --version

# 2. Update llama.cpp to latest version
cd /path/to/llama.cpp
git pull
make clean && make

# 3. Verify model compatibility
./chat-manager.sh test
```

### Model Loading Issues

#### Model File Problems
```bash
# Check if model file exists and is readable
ls -la models/
file models/*.gguf

# Verify model file integrity
# For downloaded models, check file size matches expected
du -h models/*.gguf

# Test model loading manually
llama-server --model models/your-model.gguf --port 8121 --verbose

# Common model issues:
# 1. Corrupted download - re-download
./chat-manager.sh download-model <url> <filename>

# 2. Wrong format - ensure .gguf format
# 3. Insufficient memory - use smaller model
# 4. Model architecture not supported - try different model
```

#### Memory-Related Model Issues
```bash
# Check available memory before loading
free -h

# Model memory requirements (approximate):
# 0.5B parameters: ~400MB-800MB RAM
# 1B parameters: ~800MB-1.5GB RAM
# 3B parameters: ~2GB-4GB RAM
# 7B parameters: ~4GB-8GB RAM

# If model won't load due to memory:
# 1. Close other applications
# 2. Use smaller model
# 3. Reduce context size in cm.conf
# 4. Enable swap (not recommended for performance)
sudo swapon -s
```

---

## 🔄 Model Management Issues

### Model Download Problems

#### Download Failures
```bash
# Check internet connectivity
ping huggingface.co
curl -I https://huggingface.co

# Download with verbose output
./chat-manager.sh download-model <url> <filename> 2>&1 | tee download.log

# Common download issues:
# 1. Network timeout - try again
# 2. Insufficient disk space
df -h

# 3. Permission issues
mkdir -p models
chmod 755 models

# 4. Curl/wget not available
sudo apt install curl wget  # Ubuntu/Debian
brew install curl wget      # macOS

# Manual download as fallback
cd models
wget "https://huggingface.co/model/path/file.gguf"
# OR
curl -L -o "filename.gguf" "https://huggingface.co/model/path/file.gguf"
```

#### Model Organization
```bash
# Check models directory structure
./chat-manager.sh list-models

# Organize models by size/type
mkdir -p models/{small,medium,large,coding}
mv models/*0.5b* models/small/
mv models/*1b* models/small/
mv models/*3b* models/medium/
mv models/*7b* models/large/
mv models/*code* models/coding/

# Update cm.conf to point to organized structure
MODELS_DIR="$INSTALL_DIR/models/small"
```

### Model Switching Issues

#### Dynamic Switching Failures
```bash
# Check if target model exists
./chat-manager.sh list-models

# Test model switching with verbose output
DEBUG=true ./chat-manager.sh switch-model your-model.gguf

# Common switching issues:
# 1. Model file not found
ls -la models/your-model.gguf

# 2. Insufficient memory for new model
free -h

# 3. Previous model still loaded
./chat-manager.sh stop-llamacpp
sleep 5
./chat-manager.sh start-llamacpp your-model.gguf

# 4. Permission issues
chmod 644 models/*.gguf

# 5. Timeout during switch
# Increase MODEL_SWITCH_TIMEOUT in cm.conf
```

#### Model Validation
```bash
# Verify model file format
file models/*.gguf

# Test model manually
llama-server --model models/your-model.gguf --port 8121 &
sleep 10
curl http://localhost:8121/v1/models
kill %1

# Check model metadata
strings models/your-model.gguf | head -20
```

---

## 🌐 Network Issues

### Connection Timeouts

#### Service Communication Issues
```bash
# Test inter-service communication
curl -v http://localhost:8120/v1/models    # llama.cpp server
curl -v http://localhost:3333/api/models   # Flask application

# Check network configuration
netstat -tulpn | grep -E "(8120|3333)"

# Common timeout causes:
# 1. Overloaded system
top
htop

# 2. Network interface issues
ip addr show
ping localhost

# 3. DNS resolution problems (rare for localhost)
echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts
```

#### Firewall and Security
```bash
# Check firewall status
sudo ufw status verbose              # Ubuntu
sudo firewall-cmd --list-all        # CentOS/RHEL
sudo iptables -L                     # Generic Linux

# Allow llama-chat ports
sudo ufw allow 8120 comment "llama.cpp server"
sudo ufw allow 3333 comment "llama-chat web interface"

# SELinux issues (CentOS/RHEL)
getenforce
sudo setenforce 0  # Temporary disable for testing
# Configure properly for production
```

### Remote Access Issues

#### External Access Configuration
```bash
# Allow external connections (security consideration required)
# Edit cm.conf:
LLAMACPP_HOST=0.0.0.0  # WARNING: Allows external access
FLASK_HOST=0.0.0.0     # WARNING: Allows external access

# Safer approach - use SSH tunneling:
# On remote machine:
ssh -L 3333:localhost:3333 -L 8120:localhost:8120 user@server

# Or use nginx/apache as reverse proxy for production
```

---

## 💾 Database Issues

### SQLite Database Problems

#### Database Corruption
```bash
# Check database integrity
sqlite3 data/llama-chat.db "PRAGMA integrity_check;"

# Backup current database
cp data/llama-chat.db data/backup-$(date +%Y%m%d-%H%M%S).db

# Repair corrupted database
sqlite3 data/llama-chat.db "PRAGMA integrity_check;" > integrity.log
if grep -q "ok" integrity.log; then
    echo "Database is OK"
else
    echo "Database is corrupted - restoring from backup or recreating"
    # Option 1: Restore from backup
    cp data/backup-*.db data/llama-chat.db
    
    # Option 2: Recreate (loses chat history)
    rm -f data/llama-chat.db
    ./chat-manager.sh restart
fi
```

#### Database Permission Issues
```bash
# Fix database file permissions
chmod 644 data/llama-chat.db
chown $USER:$USER data/llama-chat.db

# Fix directory permissions
mkdir -p data
chmod 755 data
chown $USER:$USER data

# Check if database is writable
sqlite3 data/llama-chat.db "CREATE TABLE test_write (id INTEGER); DROP TABLE test_write;"
```

#### Database Performance Issues
```bash
# Check database size
ls -lh data/llama-chat.db

# Analyze database
sqlite3 data/llama-chat.db "ANALYZE;"

# Vacuum database to reclaim space
sqlite3 data/llama-chat.db "VACUUM;"

# Check for long-running queries
# Enable query logging in debug mode
DEBUG=true ./chat-manager.sh restart
./chat-manager.sh logs flask | grep -i sql
```

---

## 🐛 Debug Mode

### Enable Comprehensive Debugging

#### Application Debug Mode
```bash
# Start all services with debug enabled
DEBUG=true ./chat-manager.sh start

# Start individual services with debug
DEBUG=true ./chat-manager.sh start-llamacpp
DEBUG=true ./chat-manager.sh start-flask

# View debug logs in real-time
./chat-manager.sh follow llamacpp
./chat-manager.sh follow flask
./chat-manager.sh follow all
```

#### llama.cpp Debug Mode
```bash
# Start llama-server with verbose logging
llama-server --model models/your-model.gguf \
             --port 8120 \
             --verbose \
             --log-format text \
             > llamacpp-debug.log 2>&1 &

# Monitor debug output
tail -f llamacpp-debug.log
```

#### Flask Application Debug
```bash
# Run Flask in debug mode manually
source venv/bin/activate
export FLASK_DEBUG=1
export FLASK_ENV=development
python app.py
```

### Debug Scripts and Tools

#### Comprehensive Health Check
```bash
#!/bin/bash
# health-check.sh - Comprehensive system health check

echo "=== llama-chat Health Check - $(date) ==="
echo ""

# Check Python environment
echo "=== Python Environment ==="
echo "Python version: $(python3 --version)"
echo "Virtual environment: ${VIRTUAL_ENV:-'Not activated'}"
echo "Python executable: $(which python)"
echo ""

# Check llama.cpp installation
echo "=== llama.cpp Installation ==="
if command -v llama-server &> /dev/null; then
    echo "✓ llama-server found: $(which llama-server)"
    llama-server --version 2>/dev/null || echo "Version check failed"
else
    echo "✗ llama-server not found in PATH"
fi
echo ""

# Check dependencies
echo "=== Python Dependencies ==="
source venv/bin/activate 2>/dev/null
python -c "
try:
    import flask, requests, sqlite3
    print('✓ Core dependencies OK')
except ImportError as e:
    print(f'✗ Missing dependency: {e}')
"
echo ""

# Check processes
echo "=== Running Processes ==="
ps aux | grep -E "(llama-server|python.*app\.py)" | grep -v grep || echo "No llama-chat processes running"
echo ""

# Check ports
echo "=== Port Status ==="
for port in 8120 3333; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "✓ Port $port: IN USE"
        lsof -i :$port | tail -n +2
    else
        echo "○ Port $port: FREE"
    fi
done
echo ""

# Check models
echo "=== Models ==="
if [ -d "models" ]; then
    model_count=$(find models -name "*.gguf" 2>/dev/null | wc -l)
    echo "Found $model_count .gguf model(s):"
    find models -name "*.gguf" -exec ls -lh {} \; 2>/dev/null | head -5
    [ $model_count -gt 5 ] && echo "... and $((model_count - 5)) more"
else
    echo "✗ Models directory not found"
fi
echo ""

# Check disk space
echo "=== System Resources ==="
echo "Disk space:"
df -h . | tail -1
echo "Memory:"
free -h | grep -E "(Mem|Swap)"
echo "Load average:"
uptime
echo ""

# Check configuration
echo "=== Configuration ==="
if [ -f "cm.conf" ]; then
    echo "✓ cm.conf exists"
    grep -E "^[A-Z_]+=.*" cm.conf | head -5
else
    echo "○ cm.conf not found (will use defaults)"
fi

if [ -f "config.json" ]; then
    echo "✓ config.json exists"
    if python -m json.tool config.json >/dev/null 2>&1; then
        echo "✓ config.json syntax valid"
    else
        echo "✗ config.json syntax error"
    fi
else
    echo "○ config.json not found (will use defaults)"
fi
echo ""

# API tests
echo "=== API Health Tests ==="
if curl -s -m 5 http://localhost:8120/v1/models >/dev/null 2>&1; then
    echo "✓ llama.cpp server API responding"
else
    echo "✗ llama.cpp server API not responding"
fi

if curl -s -m 5 http://localhost:3333/api/models >/dev/null 2>&1; then
    echo "✓ Flask application API responding"
else
    echo "✗ Flask application API not responding"
fi
echo ""

echo "=== Health Check Complete ==="
```

#### Performance Monitor
```bash
#!/bin/bash
# performance-monitor.sh - Real-time performance monitoring

echo "=== llama-chat Performance Monitor ==="
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo "=== Performance Monitor - $(date) ==="
    echo ""
    
    # CPU and Memory usage
    echo "=== System Resources ==="
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage:"
    free -h | grep -E "(Mem|Swap)" | awk '{print "  " $0}'
    echo ""
    
    # Process information
    echo "=== llama-chat Processes ==="
    ps aux | grep -E "(llama-server|python.*app\.py)" | grep -v grep | \
    awk '{printf "  %-12s PID:%-8s CPU:%-6s MEM:%-6s CMD: %s\n", $1, $2, $3, $4, substr($0, index($0,$11))}'
    echo ""
    
    # Port status
    echo "=== Network Status ==="
    for port in 8120 3333; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo "  Port $port: ACTIVE"
        else
            echo "  Port $port: INACTIVE"
        fi
    done
    echo ""
    
    # Recent logs (last 3 lines)
    echo "=== Recent Activity ==="
    if [ -f logs/llamacpp.log ]; then
        echo "llama.cpp:"
        tail -n 2 logs/llamacpp.log 2>/dev/null | sed 's/^/  /'
    fi
    if [ -f logs/flask.log ]; then
        echo "Flask:"
        tail -n 2 logs/flask.log 2>/dev/null | sed 's/^/  /'
    fi
    echo ""
    
    # API response times
    echo "=== API Response Times ==="
    start_time=$(date +%s%N)
    if curl -s -m 2 http://localhost:8120/v1/models >/dev/null 2>&1; then
        end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))
        echo "  llama.cpp API: ${response_time}ms"
    else
        echo "  llama.cpp API: NO RESPONSE"
    fi
    
    start_time=$(date +%s%N)
    if curl -s -m 2 http://localhost:3333/api/models >/dev/null 2>&1; then
        end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))
        echo "  Flask API: ${response_time}ms"
    else
        echo "  Flask API: NO RESPONSE"
    fi
    
    sleep 5
done
```

#### Log Analyzer
```bash
#!/bin/bash
# log-analyzer.sh - Analyze logs for common issues

echo "=== llama-chat Log Analyzer ==="
echo ""

# Analyze llama.cpp logs
if [ -f logs/llamacpp.log ]; then
    echo "=== llama.cpp Log Analysis ==="
    echo "Recent errors:"
    grep -i error logs/llamacpp.log | tail -5 | sed 's/^/  /'
    
    echo "Memory warnings:"
    grep -i "memory\|oom\|allocation" logs/llamacpp.log | tail -3 | sed 's/^/  /'
    
    echo "Model loading issues:"
    grep -i "model\|load\|gguf" logs/llamacpp.log | tail -3 | sed 's/^/  /'
    echo ""
fi

# Analyze Flask logs
if [ -f logs/flask.log ]; then
    echo "=== Flask Log Analysis ==="
    echo "Recent errors:"
    grep -i "error\|exception\|traceback" logs/flask.log | tail -5 | sed 's/^/  /'
    
    echo "Database issues:"
    grep -i "database\|sqlite\|sql" logs/flask.log | tail -3 | sed 's/^/  /'
    
    echo "API issues:"
    grep -i "timeout\|connection\|api" logs/flask.log | tail -3 | sed 's/^/  /'
    echo ""
fi

# Analyze monitor logs
if [ -f logs/monitor.log ]; then
    echo "=== Monitor Log Analysis ==="
    echo "Service restarts:"
    grep -i "restart\|crash" logs/monitor.log | tail -5 | sed 's/^/  /'
    echo ""
fi

echo "=== Log Analysis Complete ==="
```

Save this as `log-analyzer.sh` and make executable with `chmod +x log-analyzer.sh`

---

## 📊 System Information

### Collect System Info for Bug Reports

#### System Information Collection Script
```bash
#!/bin/bash
# system-info.sh - Collect comprehensive system information

echo "=== llama-chat System Information Report ==="
echo "Generated: $(date)"
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo ""

echo "=== Operating System ==="
echo "Kernel: $(uname -a)"
if [ -f /etc/os-release ]; then
    echo "Distribution:"
    cat /etc/os-release | grep -E "(NAME|VERSION)" | sed 's/^/  /'
elif [ -f /etc/lsb-release ]; then
    echo "Distribution:"
    cat /etc/lsb-release | sed 's/^/  /'
fi
echo ""

echo "=== Hardware Information ==="
echo "CPU:"
if [ -f /proc/cpuinfo ]; then
    grep -E "(model name|cpu cores|siblings)" /proc/cpuinfo | head -3 | sed 's/^/  /'
    echo "  CPU threads: $(nproc)"
fi
echo "Memory:"
if [ -f /proc/meminfo ]; then
    grep -E "(MemTotal|MemAvailable|SwapTotal)" /proc/meminfo | sed 's/^/  /'
fi
echo "Disk space:"
df -h . | tail -1 | awk '{print "  Available: " $4 " (" $5 " used)"}'
echo ""

echo "=== Software Versions ==="
echo "Python: $(python3 --version 2>&1)"
echo "pip: $(pip --version 2>&1)"
if command -v llama-server &> /dev/null; then
    echo "llama.cpp: $(llama-server --version 2>&1 | head -1)"
else
    echo "llama.cpp: NOT INSTALLED"
fi
echo "Git: $(git --version 2>&1)"
echo ""

echo "=== llama-chat Installation ==="
echo "Installation directory: $(pwd)"
echo "Virtual environment: ${VIRTUAL_ENV:-'Not activated'}"

if [ -f cm.conf ]; then
    echo "Configuration (cm.conf):"
    grep -E "^[A-Z_]+=.*" cm.conf | sed 's/^/  /' | head -10
else
    echo "Configuration: No cm.conf found"
fi

if [ -f config.json ]; then
    echo "JSON config: Present"
    if python -m json.tool config.json >/dev/null 2>&1; then
        echo "  Syntax: Valid"
    else
        echo "  Syntax: INVALID"
    fi
else
    echo "JSON config: Not found"
fi
echo ""

echo "=== Service Status ==="
echo "Processes:"
ps aux | grep -E "(llama-server|python.*app\.py)" | grep -v grep | sed 's/^/  /' || echo "  No llama-chat processes running"

echo "Ports:"
for port in 8120 3333; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "  Port $port: IN USE"
    else
        echo "  Port $port: FREE"
    fi
done
echo ""

echo "=== Models ==="
if [ -d models ]; then
    echo "Models directory: $(pwd)/models"
    echo "Model count: $(find models -name "*.gguf" 2>/dev/null | wc -l)"
    echo "Models:"
    find models -name "*.gguf" -exec ls -lh {} \; 2>/dev/null | \
    awk '{print "  " $9 " (" $5 ")"}'| head -10
else
    echo "Models directory: NOT FOUND"
fi
echo ""

echo "=== Recent Logs ==="
for logfile in llamacpp flask monitor; do
    if [ -f "logs/$logfile.log" ]; then
        echo "$logfile.log (last 3 lines):"
        tail -n 3 "logs/$logfile.log" 2>/dev/null | sed 's/^/  /'
    fi
done
echo ""

echo "=== Network Connectivity ==="
echo "Localhost connectivity:"
if curl -s -m 5 http://localhost:8120/v1/models >/dev/null 2>&1; then
    echo "  llama.cpp API: OK"
else
    echo "  llama.cpp API: FAILED"
fi

if curl -s -m 5 http://localhost:3333/api/models >/dev/null 2>&1; then
    echo "  Flask API: OK"
else
    echo "  Flask API: FAILED"
fi

echo "Internet connectivity:"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "  Internet: OK"
else
    echo "  Internet: FAILED"
fi
echo ""

echo "=== Environment Variables ==="
env | grep -E "(PATH|PYTHON|VIRTUAL|LLAMA|FLASK)" | sed 's/^/  /' | head -10
echo ""

echo "=== System Information Report Complete ==="
```

---

## 🆘 Getting Help

### Before Reporting Issues

1. **Run the health check script** to identify obvious problems
2. **Check this troubleshooting guide** for known solutions  
3. **Enable debug mode** and collect relevant logs
4. **Try the emergency reset** procedure if nothing else works
5. **Search existing issues** on GitHub

### Bug Report Template

When reporting issues, include this information:

```markdown
## System Information
**OS:** [Ubuntu 22.04, macOS 13.5, Windows 11 WSL2, etc.]
**CPU:** [Intel i5-8400, AMD Ryzen 5 3600, Apple M1, etc.]
**RAM:** [8GB, 16GB, etc.]
**Storage:** [SSD/HDD, available space]

## Software Versions
**Python:** [3.9.7, 3.11.4, etc.]
**llama.cpp:** [commit hash or version]
**llama-chat:** [commit hash or release version]

## Installation Method
- [ ] Automatic installer (`install.sh`)
- [ ] Manual installation
- [ ] Docker (if available)
- [ ] Custom setup

## Configuration
**cm.conf settings:**
```bash
CONTEXT_SIZE=2048
GPU_LAYERS=0
THREADS=4
# ... other relevant settings
```

**Models in use:**
- Model name and size
- Download source

## Issue Description
**What were you trying to do?**
[Clear description of the task]

**What happened instead?**
[Actual behavior observed]

**What did you expect to happen?**
[Expected behavior]

## Steps to Reproduce
1. [First step]
2. [Second step]  
3. [Third step]
4. [Error occurs]

## Error Messages and Logs
**Error messages:**
```
[Paste exact error messages here]
```

**Relevant logs:**
```bash
# llama.cpp logs
./chat-manager.sh logs llamacpp 20

# Flask logs  
./chat-manager.sh logs flask 20

# System info
./chat-manager.sh status
```

## Troubleshooting Attempted
- [ ] Checked this troubleshooting guide
- [ ] Ran health check script
- [ ] Tried emergency reset
- [ ] Enabled debug mode
- [ ] Checked system resources
- [ ] Updated llama.cpp
- [ ] Tried different model
- [ ] Other: [describe]

## Additional Context
[Any other relevant information, screenshots, etc.]
```

### Support Channels

- **GitHub Issues**: https://github.com/ukkit/llama-chat/issues
- **GitHub Discussions**: https://github.com/ukkit/llama-chat/discussions  
- **Documentation**: README.md, docs/ folder, and this troubleshooting guide

### Community Resources

- **llama.cpp Issues**: https://github.com/ggerganov/llama.cpp/issues
- **Model Hub**: https://huggingface.co/models?other=gguf
- **Performance Discussions**: Community benchmarks and optimization tips

---

## 🚨 Emergency Procedures

### Complete System Reset

When everything else fails, use this nuclear option:

```bash
#!/bin/bash
# emergency-reset.sh - Complete llama-chat reset

echo "=== EMERGENCY RESET - This will delete all data! ==="
read -p "Are you sure? Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Reset cancelled"
    exit 1
fi

echo "Starting emergency reset..."

# 1. Stop all services aggressively
echo "Stopping all services..."
./chat-manager.sh force-cleanup 2>/dev/null || true
pkill -f "llama-server" 2>/dev/null || true
pkill -f "python.*app\.py" 2>/dev/null || true

# 2. Remove all runtime files
echo "Removing runtime files..."
rm -f *.pid *.log
rm -rf logs/
rm -rf __pycache__/
rm -rf *.pyc

# 3. Reset virtual environment
echo "Resetting virtual environment..."
rm -rf venv/
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# 4. Reset configuration
echo "Resetting configuration..."
rm -f cm.conf config.json

# 5. Reset database (LOSES ALL CHAT HISTORY)
echo "Resetting database..."
rm -rf data/
mkdir -p data

# 6. Verify llama.cpp installation
echo "Checking llama.cpp..."
if ! command -v llama-server &> /dev/null; then
    echo "ERROR: llama-server not found. Please install llama.cpp first."
    echo "See: https://github.com/ggerganov/llama.cpp"
    exit 1
fi

# 7. Download a basic model if none exist
if [ ! -d models ] || [ $(find models -name "*.gguf" | wc -l) -eq 0 ]; then
    echo "No models found. Downloading basic model..."
    mkdir -p models
    ./chat-manager.sh download-model \
        "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
        "qwen2.5-0.5b-instruct-q4_0.gguf"
fi

# 8. Test installation
echo "Testing installation..."
./chat-manager.sh test

echo ""
echo "Emergency reset complete!"
echo "Try starting services: ./chat-manager.sh start"
```

### Recovery from Corruption

```bash
#!/bin/bash
# recovery.sh - Recover from corrupted installation

echo "=== llama-chat Recovery Procedure ==="

# Backup existing data
echo "Creating backups..."
[ -f data/llama-chat.db ] && cp data/llama-chat.db backup-db-$(date +%Y%m%d-%H%M%S).db
[ -f cm.conf ] && cp cm.conf backup-cm.conf-$(date +%Y%m%d-%H%M%S)
[ -f config.json ] && cp config.json backup-config.json-$(date +%Y%m%d-%H%M%S)

# Stop services safely
echo "Stopping services..."
./chat-manager.sh stop 2>/dev/null || ./chat-manager.sh force-cleanup

# Verify and repair Python environment
echo "Checking Python environment..."
if [ ! -d venv ] || ! source venv/bin/activate; then
    echo "Recreating virtual environment..."
    rm -rf venv
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# Verify application files
echo "Checking application files..."
if [ ! -f app.py ]; then
    echo "ERROR: app.py missing. Reinstall llama-chat."
    exit 1
fi

# Check and repair database
echo "Checking database..."
if [ -f data/llama-chat.db ]; then
    if ! sqlite3 data/llama-chat.db "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "Database corrupted. Creating new database..."
        mv data/llama-chat.db data/corrupted-$(date +%Y%m%d-%H%M%S).db
        mkdir -p data
    fi
else
    mkdir -p data
fi

# Test basic functionality
echo "Testing basic functionality..."
if ./chat-manager.sh test; then
    echo "Recovery successful!"
    echo "Start services with: ./chat-manager.sh start"
else
    echo "Recovery failed. Consider complete reinstallation."
    exit 1
fi
```

### Backup and Restore Procedures

```bash
#!/bin/bash
# backup.sh - Create complete backup

BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup data
[ -d data ] && cp -r data "$BACKUP_DIR/"

# Backup configuration
[ -f cm.conf ] && cp cm.conf "$BACKUP_DIR/"
[ -f config.json ] && cp config.json "$BACKUP_DIR/"

# Backup logs (recent only)
if [ -d logs ]; then
    mkdir -p "$BACKUP_DIR/logs"
    find logs -name "*.log" -mtime -7 -exec cp {} "$BACKUP_DIR/logs/" \;
fi

# Create restore script
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
echo "Restoring llama-chat backup..."
./chat-manager.sh stop 2>/dev/null || true
[ -d data ] && cp -r data/* ../data/ 2>/dev/null || true
[ -f cm.conf ] && cp cm.conf ../ 2>/dev/null || true
[ -f config.json ] && cp config.json ../ 2>/dev/null || true
echo "Restore complete. Start services with: ./chat-manager.sh start"
EOF
chmod +x "$BACKUP_DIR/restore.sh"

echo "Backup created: $BACKUP_DIR"
echo "To restore: cd $BACKUP_DIR && ./restore.sh"
```

---

**Remember:** Most issues can be resolved by following this guide systematically. When in doubt, start with the health check script and work through the relevant sections. The llama-chat system is designed to be robust, but proper troubleshooting requires understanding the interaction between llama.cpp, Flask, and the model files.

**Quick Recovery Steps:**
1. `./chat-manager.sh test` - Identify the problem
2. `./chat-manager.sh force-cleanup` - Clean up stuck processes  
3. Check logs: `./chat-manager.sh logs all 50`
4. Try emergency reset if needed
5. Ask for help with detailed information if still stuck

---

*This troubleshooting guide covers llama-chat v2.1+ with llama.cpp backend and enhanced management features.*