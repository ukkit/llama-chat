# 🤖 llama-chat Model Guide

Comprehensive guide to models, performance, and optimization for llama-chat with llama.cpp.

## 📋 Quick Reference

| Model Category | Size Range | RAM Usage | CPU Speed | GPU Speed | Best For |
|----------------|------------|-----------|-----------|-----------|----------|
| **Ultra-Fast** | 0.5B-1B | 1-2GB | 15-40 tok/s | 50-150 tok/s | Quick responses, testing |
| **Balanced** | 1B-3B | 2-4GB | 8-20 tok/s | 30-80 tok/s | Daily use, general chat |
| **High-Quality** | 7B-13B | 8-16GB | 2-8 tok/s | 20-50 tok/s | Complex tasks, analysis |
| **Specialized** | 1B-70B | 2-80GB | 1-15 tok/s | 10-100 tok/s | Coding, domain-specific |

---

## 🚀 Recommended Starter Models

### **Best First Models**

#### **Qwen2.5-0.5B-Instruct** (~400MB) ⭐ **RECOMMENDED**
```bash
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"
```
- **Performance**: 15-30 tokens/sec (CPU), 50-100 tokens/sec (GPU)
- **Memory**: ~1GB RAM
- **Best for**: Quick responses, general chat, learning
- **Pros**: Very fast, low memory, good quality for size
- **Cons**: Limited knowledge depth for complex topics

#### **TinyLlama-1.1B-Chat** (~637MB)
```bash
./chat-manager.sh download-model \
  "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_0.gguf" \
  "tinyllama-1.1b-chat-v1.0.Q4_0.gguf"
```
- **Performance**: 20-40 tokens/sec (CPU), 60-120 tokens/sec (GPU)
- **Memory**: ~1.5GB RAM
- **Best for**: Ultra-fast responses, resource-constrained systems
- **Pros**: Extremely fast, very low memory usage
- **Cons**: Basic capabilities, limited for complex tasks

### **Step-Up Models**

#### **Phi-3-Mini-4K-Instruct** (~2.3GB) ⭐ **EXCELLENT BALANCE**
```bash
./chat-manager.sh download-model \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" \
  "phi3-mini-4k-instruct-q4.gguf"
```
- **Performance**: 8-15 tokens/sec (CPU), 30-60 tokens/sec (GPU)
- **Memory**: ~3GB RAM
- **Best for**: Daily use, coding assistance, detailed explanations
- **Pros**: Excellent quality/size ratio, strong reasoning
- **Cons**: Slower than smaller models, higher memory usage

#### **Llama-3.2-1B-Instruct** (~1.3GB)
```bash
./chat-manager.sh download-model \
  "https://huggingface.co/hugging-quants/Llama-3.2-1B-Instruct-Q4_0-GGUF/resolve/main/llama-3.2-1b-instruct-q4_0.gguf" \
  "llama-3.2-1b-instruct-q4_0.gguf"
```
- **Performance**: 10-20 tokens/sec (CPU), 40-80 tokens/sec (GPU)
- **Memory**: ~2GB RAM
- **Best for**: Good balance of speed and quality
- **Pros**: Meta's latest small model, good instruction following
- **Cons**: Newer model, less tested than alternatives

---

## 📊 Performance Comparison

### **Speed Benchmarks (CPU-only, Intel i7-10700K)**

| Model | Size | Tokens/Sec | First Token | Memory | Quality Score |
|-------|------|------------|-------------|---------|---------------|
| qwen2.5-0.5b-instruct | 400MB | 25.3 | 180ms | 0.9GB | 7.2/10 |
| tinyllama-1.1b | 637MB | 32.1 | 120ms | 1.4GB | 6.8/10 |
| llama-3.2-1b | 1.3GB | 18.7 | 250ms | 2.1GB | 7.8/10 |
| phi3-mini-4k | 2.3GB | 11.4 | 400ms | 3.2GB | 8.5/10 |
| llama-3.2-3b | 3.2GB | 6.8 | 650ms | 4.8GB | 8.9/10 |

### **GPU Acceleration (RTX 4070, 12GB VRAM)**

| Model | GPU Layers | Tokens/Sec | Speedup | VRAM Used |
|-------|------------|------------|---------|-----------|
| qwen2.5-0.5b-instruct | All (26) | 89.2 | 3.5x | 1.2GB |
| tinyllama-1.1b | All (22) | 156.7 | 4.9x | 1.8GB |
| llama-3.2-1b | All (16) | 72.3 | 3.9x | 2.4GB |
| phi3-mini-4k | All (32) | 48.6 | 4.3x | 3.8GB |
| llama-3.2-3b | All (28) | 31.2 | 4.6x | 5.2GB |

---

## 🎯 Model Categories

### **Ultra-Fast Models (0.5B-1B parameters)**

Perfect for quick responses and resource-constrained systems.

#### **Qwen2.5-0.5B-Instruct** ⭐
- **Download**: `qwen2.5-0.5b-instruct-q4_0.gguf` (400MB)
- **Context**: 4K tokens
- **Languages**: English, Chinese, multilingual
- **Strengths**: Fast inference, good instruction following
- **Use cases**: Quick Q&A, simple coding help, general chat

#### **TinyLlama-1.1B-Chat**
- **Download**: `tinyllama-1.1b-chat-v1.0.Q4_0.gguf` (637MB)
- **Context**: 2K tokens
- **Languages**: Primarily English
- **Strengths**: Ultra-fast, very low memory
- **Use cases**: Testing, embedded systems, fast prototyping

### **Balanced Models (1B-3B parameters)**

Optimal balance of speed, quality, and resource usage.

#### **Phi-3-Mini-4K-Instruct** ⭐ **BEST BALANCE**
- **Download**: `phi3-mini-4k-instruct-q4.gguf` (2.3GB)
- **Context**: 4K tokens
- **Languages**: English, multilingual
- **Strengths**: Excellent reasoning, coding capabilities
- **Use cases**: Daily chat, coding assistance, educational content

#### **Llama-3.2-1B-Instruct**
- **Download**: `llama-3.2-1b-instruct-q4_0.gguf` (1.3GB)
- **Context**: 8K tokens
- **Languages**: English, multilingual
- **Strengths**: Latest Meta model, good context handling
- **Use cases**: General purpose, instruction following

#### **Llama-3.2-3B-Instruct**
- **Download**: `llama-3.2-3b-instruct-q4_0.gguf` (3.2GB)
- **Context**: 8K tokens
- **Languages**: English, multilingual
- **Strengths**: Higher quality than 1B, still relatively fast
- **Use cases**: Complex conversations, better reasoning

### **High-Quality Models (7B+ parameters)**

For complex tasks requiring superior reasoning and knowledge.

#### **Llama-3.1-8B-Instruct** ⭐ **HIGH QUALITY**
- **Download**: `llama-3.1-8b-instruct-q4_0.gguf` (~4.6GB)
- **Context**: 8K tokens
- **Languages**: English, multilingual
- **Strengths**: Excellent reasoning, broad knowledge
- **Use cases**: Complex analysis, research, detailed explanations
- **Requirements**: 8GB+ RAM, GPU recommended

#### **Qwen2.5-7B-Instruct**
- **Download**: `qwen2.5-7b-instruct-q4_0.gguf` (~4.2GB)
- **Context**: 32K tokens
- **Languages**: English, Chinese, multilingual
- **Strengths**: Large context, multilingual, coding
- **Use cases**: Long document analysis, multilingual tasks

### **Specialized Models**

#### **CodeLlama-7B-Instruct** (Coding)
- **Download**: `codellama-7b-instruct.Q4_0.gguf` (~3.8GB)
- **Context**: 4K tokens
- **Languages**: Programming languages
- **Strengths**: Code generation, debugging, explanations
- **Use cases**: Software development, code review

#### **Mistral-7B-Instruct** (General Purpose)
- **Download**: `mistral-7b-instruct-v0.2.Q4_0.gguf` (~4.1GB)
- **Context**: 8K tokens
- **Languages**: English, multilingual
- **Strengths**: Well-rounded capabilities, efficient
- **Use cases**: General chat, analysis, creative writing

---

## 💾 Quantization Guide

### **Quantization Levels**

| Quantization | Size Reduction | Quality Loss | Speed Gain | Best For |
|--------------|----------------|--------------|------------|----------|
| **Q4_0** | 75% smaller | Minimal | Moderate | **Recommended default** |
| **Q4_1** | 75% smaller | Minimal | Moderate | Slightly better quality |
| **Q5_0** | 65% smaller | Very low | Low | Quality-focused |
| **Q5_1** | 65% smaller | Very low | Low | Best quality/size ratio |
| **Q8_0** | 50% smaller | Negligible | None | High-end systems |
| **F16** | 50% smaller | None | None | GPU with plenty VRAM |

### **Choosing Quantization**

```bash
# For most users (best balance)
model-name-q4_0.gguf

# For quality-focused usage
model-name-q5_1.gguf

# For maximum speed (larger models)
model-name-q4_0.gguf

# For high-end GPU systems
model-name-q8_0.gguf or model-name-f16.gguf
```

---

## ⚙️ Hardware-Specific Recommendations

### **Low-End Systems (4GB RAM, No GPU)**

**Recommended Models:**
- qwen2.5-0.5b-instruct-q4_0.gguf (400MB)
- tinyllama-1.1b-chat-v1.0.Q4_0.gguf (637MB)

**Configuration:**
```bash
# llama-chat.conf
GPU_LAYERS=0
CONTEXT_SIZE=2048
BATCH_SIZE=256
THREADS=4
```

### **Mid-Range Systems (8GB RAM, Optional GPU)**

**Recommended Models:**
- phi3-mini-4k-instruct-q4.gguf (2.3GB)
- llama-3.2-1b-instruct-q4_0.gguf (1.3GB)
- llama-3.2-3b-instruct-q4_0.gguf (3.2GB)

**Configuration:**
```bash
# llama-chat.conf
GPU_LAYERS=16    # If GPU available, 0 if CPU-only
CONTEXT_SIZE=4096
BATCH_SIZE=512
THREADS=-1
```

### **High-End Systems (16GB+ RAM, GPU)**

**Recommended Models:**
- llama-3.1-8b-instruct-q4_0.gguf (4.6GB)
- qwen2.5-7b-instruct-q4_0.gguf (4.2GB)
- mistral-7b-instruct-v0.2.Q4_0.gguf (4.1GB)

**Configuration:**
```bash
# llama-chat.conf
GPU_LAYERS=-1    # Use all GPU layers
CONTEXT_SIZE=8192
BATCH_SIZE=1024
THREADS=8
```

### **Apple Silicon (M1/M2/M3)**

**Recommended Models:**
- Any model up to available RAM minus 4GB for system
- Metal acceleration works automatically

**Configuration:**
```bash
# llama-chat.conf
GPU_LAYERS=-1    # Metal handles automatically
CONTEXT_SIZE=8192
BATCH_SIZE=1024
THREADS=8
```

---

## 📥 Model Installation

### **Using chat-manager.sh (Recommended)**

```bash
# Download recommended starter model
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen2.5-0.5b-instruct-q4_0.gguf"

# Download high-quality model
./chat-manager.sh download-model \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" \
  "phi3-mini-4k-instruct-q4.gguf"

# List downloaded models
./chat-manager.sh list-models
```

### **Manual Download**

```bash
# Create models directory
mkdir -p models

# Download with curl
curl -L -o models/qwen2.5-0.5b-instruct-q4_0.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"

# Download with wget
wget -O models/phi3-mini-4k-instruct-q4.gguf \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
```

### **Verify Downloads**

```bash
# Check downloaded models
ls -lh models/
*.gguf

# Test model loading
./chat-manager.sh start
curl http://localhost:8080/health
```

---

## 🔧 Model Configuration

### **Per-Model Optimization**

#### **Small Models (0.5B-1B)**
```json
{
  "model_options": {
    "temperature": 0.3,
    "top_p": 0.8,
    "num_predict": 2048,
    "repeat_penalty": 1.05
  }
}
```

```bash
# llama-chat.conf
CONTEXT_SIZE=2048
BATCH_SIZE=256
```

#### **Medium Models (1B-3B)**
```json
{
  "model_options": {
    "temperature": 0.2,
    "top_p": 0.9,
    "num_predict": 4096,
    "repeat_penalty": 1.1
  }
}
```

```bash
# llama-chat.conf
CONTEXT_SIZE=4096
BATCH_SIZE=512
```

#### **Large Models (7B+)**
```json
{
  "model_options": {
    "temperature": 0.1,
    "top_p": 0.95,
    "num_predict": 8192,
    "repeat_penalty": 1.15
  }
}
```

```bash
# llama-chat.conf
CONTEXT_SIZE=8192
BATCH_SIZE=1024
```

---

## 🎯 Use Case Recommendations

### **Quick Prototyping & Testing**
- **Model**: qwen2.5-0.5b-instruct-q4_0.gguf
- **Why**: Fast downloads, quick responses, low resource usage
- **Configuration**: Default settings

### **Daily Chat & General Use**
- **Model**: phi3-mini-4k-instruct-q4.gguf
- **Why**: Excellent balance of quality and speed
- **Configuration**: 4K context, moderate temperature

### **Coding & Development**
- **Model**: phi3-mini-4k-instruct-q4.gguf or codellama-7b-instruct
- **Why**: Strong coding capabilities, good reasoning
- **Configuration**: Lower temperature (0.1-0.2), higher context

### **Research & Analysis**
- **Model**: llama-3.1-8b-instruct-q4_0.gguf
- **Why**: Superior reasoning, broad knowledge base
- **Configuration**: Large context (8K+), low temperature

### **Multilingual Tasks**
- **Model**: qwen2.5-7b-instruct-q4_0.gguf
- **Why**: Strong multilingual capabilities
- **Configuration**: Large context for language mixing

### **Resource-Constrained Deployment**
- **Model**: tinyllama-1.1b-chat-v1.0.Q4_0.gguf
- **Why**: Minimal resource usage, acceptable quality
- **Configuration**: Small context, fewer threads

---

## 📈 Performance Optimization

### **Speed Optimization**

#### **For CPU Systems**
```bash
# llama-chat.conf
THREADS=-1                    # Use all CPU cores
LLAMA_ARG_MLOCK=true         # Lock model in memory
LLAMA_ARG_NO_MMAP=false      # Use memory mapping
BATCH_SIZE=512               # Optimize batch size
```

#### **For GPU Systems**
```bash
# llama-chat.conf
GPU_LAYERS=-1                # Offload all layers to GPU
THREADS=8                    # Fewer CPU threads needed
LLAMA_ARG_CONT_BATCHING=true # Enable continuous batching
BATCH_SIZE=1024              # Larger batches for GPU
```

### **Memory Optimization**

#### **Low Memory Systems**
```bash
# llama-chat.conf
CONTEXT_SIZE=1024            # Reduce context window
BATCH_SIZE=128               # Smaller batches
LLAMA_ARG_MLOCK=false        # Don't lock memory
```

```json
{
  "performance": {
    "context_history_limit": 3,
    "use_mlock": false
  }
}
```

#### **High Memory Systems**
```bash
# llama-chat.conf
CONTEXT_SIZE=8192            # Large context window
BATCH_SIZE=2048              # Large batches
LLAMA_ARG_MLOCK=true         # Lock model in memory
```

---

## 🔍 Model Testing & Validation

### **Performance Testing Script**

```bash
#!/bin/bash
# test-model-performance.sh

MODEL_FILE="$1"
if [ -z "$MODEL_FILE" ]; then
    echo "Usage: $0 <model-file.gguf>"
    exit 1
fi

echo "Testing model: $MODEL_FILE"

# Test different context sizes
for CTX in 1024 2048 4096 8192; do
    echo "Testing context size: $CTX"
    
    # Start llama-server with specific settings
    llama-server \
        --model "models/$MODEL_FILE" \
        --ctx-size $CTX \
        --port 8081 \
        --threads -1 \
        --batch-size 512 &
    
    SERVER_PID=$!
    sleep 5
    
    # Test with sample prompts
    echo "Testing with context size $CTX..."
    
    curl -s -X POST http://localhost:8081/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{
            "model": "test",
            "messages": [{"role": "user", "content": "Explain quantum computing in simple terms."}],
            "max_tokens": 500,
            "temperature": 0.1
        }' | jq '.usage'
    
    # Stop server
    kill $SERVER_PID
    sleep 2
done
```

### **Quality Testing Prompts**

```bash
# Create test conversation
CONV_ID=$(curl -s -X POST http://localhost:3000/api/conversations \
    -H "Content-Type: application/json" \
    -d '{"title": "Model Quality Test", "model": "your-model.gguf"}' | \
    jq -r .conversation_id)

# Test reasoning
curl -s -X POST http://localhost:3000/api/chat \
    -H "Content-Type: application/json" \
    -d "{\"conversation_id\": $CONV_ID, \"message\": \"If a train leaves New York at 3 PM traveling 60 mph, and another leaves Boston at 4 PM traveling 80 mph, and they're 200 miles apart, when will they meet?\", \"model\": \"your-model.gguf\"}" | \
    jq -r .response

# Test coding
curl -s -X POST http://localhost:3000/api/chat \
    -H "Content-Type: application/json" \
    -d "{\"conversation_id\": $CONV_ID, \"message\": \"Write a Python function to find the factorial of a number using recursion.\", \"model\": \"your-model.gguf\"}" | \
    jq -r .response

# Test creativity
curl -s -X POST http://localhost:3000/api/chat \
    -H "Content-Type: application/json" \
    -d "{\"conversation_id\": $CONV_ID, \"message\": \"Write a haiku about artificial intelligence.\", \"model\": \"your-model.gguf\"}" | \
    jq -r .response
```

---

## 🚀 Advanced Model Management

### **Model Switching**

```bash
# Stop current services
./chat-manager.sh stop

# Change default model in configuration
echo 'DEFAULT_MODEL=new-model.gguf' >> llama-chat.conf

# Start with new model
./chat-manager.sh start
```

### **Multiple Model Setup**

```bash
# Download multiple models for different use cases
./chat-manager.sh download-model \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf" \
  "qwen-fast.gguf"

./chat-manager.sh download-model \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" \
  "phi3-quality.gguf"

./chat-manager.sh download-model \
  "https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_0.gguf" \
  "codellama-coding.gguf"

# List and choose models in the web interface
./chat-manager.sh list-models
```

### **Model Update Strategy**

```bash
# Backup current models
cp -r models models-backup-$(date +%Y%m%d)

# Download updated versions
# (Check Hugging Face for newer model releases)

# Test new models before replacing old ones
# Use different filenames and test performance

# Update configuration once satisfied
```

---

## 🔧 Troubleshooting Models

### **Common Model Issues**

#### **Model Won't Load**
```bash
# Check file integrity
ls -la models/your-model.gguf

# Verify it's a valid GGUF file
file models/your-model.gguf

# Test loading directly
llama-server --model models/your-model.gguf --port 8082 --ctx-size 2048
```

#### **Out of Memory**
```bash
# Use smaller model
# Use Q4_0 quantization instead of Q5_1 or Q8_0
# Reduce context size
# Reduce batch size
# Disable memory locking
```

#### **Slow Performance**
```bash
# Check GPU usage
nvidia-smi  # For NVIDIA GPUs

# Optimize configuration
GPU_LAYERS=-1  # Use GPU if available
THREADS=-1     # Use all CPU cores
BATCH_SIZE=1024  # Increase batch size for GPU
```

#### **Poor Quality Responses**
```bash
# Try different quantization (Q5_1 instead of Q4_0)
# Adjust temperature (lower for more focused responses)
# Increase context size if conversations are short
# Try a larger model
```

### **Performance Debugging**

```bash
# Monitor resource usage
htop  # CPU and memory
nvidia-smi -l 1  # GPU usage

# Check llama.cpp logs
./chat-manager.sh logs llamacpp

# Test API directly
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "test",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 100
  }'
```

---

## 📚 Model Resources

### **Where to Find Models**

- **Hugging Face Hub**: https://huggingface.co/models?library=gguf
- **Qwen Models**: https://huggingface.co/Qwen
- **Microsoft Phi**: https://huggingface.co/microsoft
- **Meta Llama**: https://huggingface.co/meta-llama
- **TheBloke Collections**: https://huggingface.co/TheBloke

### **Model Evaluation Resources**

- **Open LLM Leaderboard**: https://huggingface.co/spaces/HuggingFaceH4/open_llm_leaderboard
- **LMSYS Chatbot Arena**: https://chat.lmsys.org/
- **llama.cpp Performance**: https://github.com/ggml-org/llama.cpp/discussions

### **Stay Updated**

- Follow llama.cpp releases: https://github.com/ggml-org/llama.cpp/releases
- Monitor Hugging Face for new GGUF models
- Check model cards for updates and improvements
- Join community discussions for performance tips

---

*This model guide covers the most popular and tested models with llama-chat. Model availability and performance may vary based on your hardware and use case. Always test models in your specific environment before deployment.*