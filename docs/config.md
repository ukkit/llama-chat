# llama-chat 🦙 Configuration Guide

Complete configuration reference for customizing your llama-chat installation with llama.cpp.

## 📋 **Quick Reference**

| Configuration Type | File/Method | Purpose |
|-------------------|------------|---------|
| **Runtime Settings** | `config.json` | Model parameters, timeouts, performance |
| **Service Configuration** | `llama-chat.conf` | Server ports, paths, GPU settings |
| **Environment** | Environment Variables | Runtime overrides and debugging |
| **Database** | `DATABASE_PATH` | SQLite database location |
| **llama.cpp** | Command line args | Server-specific configuration |

---

## 🔧 **Runtime Configuration (config.json)**

Create a `config.json` file in your project root to customize application behavior.

### **Complete Configuration Example**

```json
{
  "timeouts": {
    "llamacpp_timeout": 600,
    "llamacpp_connect_timeout": 45
  },
  "model_options": {
    "temperature": 0.1,
    "top_p": 0.95,
    "top_k": 50,
    "min_p": 0.01,
    "num_predict": 4096,
    "repeat_penalty": 1.15,
    "stop": ["\n\nHuman:", "\n\nUser:"]
  },
  "performance": {
    "context_history_limit": 15,
    "num_thread": -1,
    "use_mlock": true,
    "use_mmap": true
  },
  "system_prompt": "You are Dost, a knowledgeable and thoughtful AI assistant. Take time to provide detailed, accurate, and well-reasoned responses. Consider multiple perspectives and provide comprehensive information when helpful.",
  "response_optimization": {
    "stream": false,
    "keep_alive": "10m"
  }
}
```

---

## 🏭 **Service Configuration (llama-chat.conf)**

The main configuration file for service management and hardware optimization.

### **Complete Service Configuration**

```bash
# llama-chat Configuration File
# This file contains configuration options for llama-chat and llama.cpp server

# ============================================================================
# INSTALLATION SETTINGS
# ============================================================================

# Installation directory
INSTALL_DIR=$HOME/llama-chat

# ============================================================================
# FLASK APPLICATION SETTINGS
# ============================================================================

# Flask web server configuration
FLASK_HOST=127.0.0.1
FLASK_PORT=3000
FLASK_DEBUG=false

# ============================================================================
# LLAMA.CPP SERVER SETTINGS
# ============================================================================

# Basic server configuration
LLAMACPP_HOST=127.0.0.1
LLAMACPP_PORT=8080
MODELS_DIR=$INSTALL_DIR/models

# Model settings
DEFAULT_MODEL=
CONTEXT_SIZE=4096
GPU_LAYERS=0
THREADS=4
BATCH_SIZE=512

# ============================================================================
# ADVANCED LLAMA.CPP SERVER OPTIONS
# ============================================================================

# Processing and Performance
# LLAMA_ARG_N_PARALLEL=1
# LLAMA_ARG_CONT_BATCHING=false
# LLAMA_ARG_N_THREADS_BATCH=4
# LLAMA_ARG_N_UBATCH=512
# LLAMA_ARG_N_KEEP=-1

# Memory Management
# LLAMA_ARG_MLOCK=false
# LLAMA_ARG_NO_MMAP=false
# LLAMA_ARG_NUMA=false

# Model Loading
# LLAMA_ARG_N_CTX=4096
# LLAMA_ARG_N_BATCH=512
# LLAMA_ARG_N_GPU_LAYERS=0
# LLAMA_ARG_MAIN_GPU=0
# LLAMA_ARG_TENSOR_SPLIT=

# Security Settings
# LLAMA_ARG_API_KEY=
# LLAMA_ARG_API_KEY_FILE=

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

# Log file locations
LOG_DIR=$INSTALL_DIR/logs
LLAMACPP_LOG_FILE=$LOG_DIR/llamacpp.log
FLASK_LOG_FILE=$LOG_DIR/flask.log

# Log rotation
LOG_MAX_SIZE=100M
LOG_ROTATE_COUNT=5
```

---

## ⏱️ **Timeout Configuration**

Controls connection and response timing behavior.

### **Settings**

```json
{
  "timeouts": {
    "llamacpp_timeout": 600,
    "llamacpp_connect_timeout": 45
  }
}
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `llamacpp_timeout` | `600` | Maximum seconds to wait for AI response |
| `llamacpp_connect_timeout` | `45` | Maximum seconds to wait for connection |

### **Recommendations**

- **Fast responses**: Set `llamacpp_timeout` to `120-300` seconds
- **Complex queries**: Use `600-1200` seconds
- **Slow networks**: Increase `llamacpp_connect_timeout` to `60`
- **Local setup**: Keep defaults or reduce timeouts

---

## 🤖 **Model Options**

Fine-tune AI model behavior and response characteristics.

### **Core Parameters**

```json
{
  "model_options": {
    "temperature": 0.1,
    "top_p": 0.95,
    "top_k": 50,
    "min_p": 0.01,
    "num_predict": 4096,
    "repeat_penalty": 1.15,
    "stop": ["\n\nHuman:", "\n\nUser:"]
  }
}
```

### **Parameter Details**

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `temperature` | 0.0-2.0 | `0.1` | Response creativity (0=deterministic, 2=very creative) |
| `top_p` | 0.0-1.0 | `0.95` | Nucleus sampling threshold |
| `top_k` | 1-100 | `50` | Consider top K probable next tokens |
| `min_p` | 0.0-1.0 | `0.01` | Minimum probability threshold |
| `num_predict` | 1-8192 | `4096` | Maximum tokens to generate |
| `repeat_penalty` | 0.5-2.0 | `1.15` | Penalty for repeating tokens |
| `stop` | Array | `["\n\nHuman:", "\n\nUser:"]` | Stop generation sequences |

### **Use Case Presets**

#### **Creative Writing**
```json
{
  "temperature": 0.8,
  "top_p": 0.9,
  "top_k": 50
}
```

#### **Code Generation**
```json
{
  "temperature": 0.1,
  "top_p": 0.7,
  "top_k": 20
}
```

#### **Analytical Tasks**
```json
{
  "temperature": 0.2,
  "top_p": 0.8,
  "top_k": 25
}
```

#### **Conversational Chat**
```json
{
  "temperature": 0.3,
  "top_p": 0.85,
  "top_k": 40
}
```

---

## ⚡ **Performance Configuration**

Optimize memory usage and processing speed for llama.cpp.

### **Settings**

```json
{
  "performance": {
    "context_history_limit": 15,
    "num_thread": -1,
    "use_mlock": true,
    "use_mmap": true
  }
}
```

### **Service Configuration (llama-chat.conf)**

```bash
# Model settings
CONTEXT_SIZE=4096       # Context window size
GPU_LAYERS=0            # Number of layers to offload to GPU
THREADS=4               # CPU threads to use
BATCH_SIZE=512          # Batch size for processing

# Advanced llama.cpp settings
LLAMA_ARG_N_PARALLEL=1           # Parallel processing slots
LLAMA_ARG_CONT_BATCHING=false    # Continuous batching
LLAMA_ARG_MLOCK=false            # Lock model in memory
LLAMA_ARG_NUMA=false             # NUMA optimization
```

### **Parameter Details**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `context_history_limit` | `15` | Number of previous messages to include |
| `CONTEXT_SIZE` | `4096` | Context window size for model |
| `GPU_LAYERS` | `0` | GPU layers to offload (0 = CPU only) |
| `THREADS` | `4` | CPU threads (-1 = auto-detect) |
| `BATCH_SIZE` | `512` | Batch processing size |

### **Hardware Optimization**

#### **CPU-Only Systems**
```bash
# llama-chat.conf
GPU_LAYERS=0
THREADS=-1  # Use all CPU cores
LLAMA_ARG_MLOCK=false
LLAMA_ARG_NO_MMAP=false
```

#### **GPU Acceleration (NVIDIA)**
```bash
# llama-chat.conf
GPU_LAYERS=32           # Or -1 for all layers
THREADS=8               # Fewer CPU threads when using GPU
LLAMA_ARG_MAIN_GPU=0    # Primary GPU ID
LLAMA_ARG_N_GPU_LAYERS=32
```

#### **Apple Silicon (Metal)**
```bash
# llama-chat.conf
GPU_LAYERS=-1           # Use all GPU layers
THREADS=8
# Metal is automatically enabled during compilation
```

#### **Low Memory Systems (<8GB RAM)**
```json
{
  "performance": {
    "context_history_limit": 5,
    "use_mlock": false
  }
}
```

```bash
# llama-chat.conf
CONTEXT_SIZE=2048
BATCH_SIZE=256
LLAMA_ARG_N_CTX=2048
```

#### **High Memory Systems (>16GB RAM)**
```json
{
  "performance": {
    "context_history_limit": 25,
    "use_mlock": true
  }
}
```

```bash
# llama-chat.conf
CONTEXT_SIZE=8192
BATCH_SIZE=1024
LLAMA_ARG_N_CTX=8192
```

---

## 🎭 **System Prompt Customization**

Define your AI assistant's personality and behavior.

### **Default System Prompt**
```json
{
  "system_prompt": "You are Dost, a knowledgeable and thoughtful AI assistant. Take time to provide detailed, accurate, and well-reasoned responses. Consider multiple perspectives and provide comprehensive information when helpful."
}
```

### **Custom Prompt Examples**

#### **Technical Expert**
```json
{
  "system_prompt": "You are a senior software architect with expertise in Python, web development, and system design. Provide detailed technical explanations with code examples when helpful. Focus on best practices, performance, and maintainability."
}
```

#### **Creative Writer**
```json
{
  "system_prompt": "You are a creative writing assistant specializing in storytelling, character development, and narrative structure. Help users develop compelling stories with vivid descriptions and engaging dialogue."
}
```

#### **Educational Tutor**
```json
{
  "system_prompt": "You are a patient and encouraging tutor. Break down complex concepts into digestible steps, provide examples, and ask clarifying questions to ensure understanding. Adapt your teaching style to the student's level."
}
```

---

## 🌍 **Environment Variables**

Configure application runtime through environment variables.

### **Core Variables**

```bash
# llama.cpp Configuration
LLAMACPP_HOST=127.0.0.1
LLAMACPP_PORT=8080

# Flask Configuration  
FLASK_HOST=127.0.0.1
FLASK_PORT=3000
DEBUG=false

# Paths
MODELS_DIR=./models
DATABASE_PATH=./data/llama-chat.db
LOG_DIR=./logs

# Performance
GPU_LAYERS=0
THREADS=4
CONTEXT_SIZE=4096
```

### **Advanced Variables**

```bash
# llama.cpp Server Arguments (prefix with LLAMA_ARG_)
LLAMA_ARG_N_GPU_LAYERS=32
LLAMA_ARG_N_PARALLEL=1
LLAMA_ARG_CONT_BATCHING=false
LLAMA_ARG_MLOCK=false
LLAMA_ARG_NUMA=false
LLAMA_ARG_N_CTX=4096
LLAMA_ARG_N_BATCH=512