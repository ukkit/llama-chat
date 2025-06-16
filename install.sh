#!/bin/bash

# llama-chat Auto Installer for llama.cpp (Non-Interactive Version)
# Usage: curl -fsSL https://github.com/ukkit/llama-chat/raw/main/install.sh | bash
# Or: wget -O- https://github.com/ukkit/llama-chat/raw/main/install.sh | bash

# For better compatibility, try to use bash if available
if command -v bash >/dev/null 2>&1; then
    if [ -z "$BASH_VERSION" ]; then
        # Re-execute with bash if we're not already running in bash
        exec bash "$0" "$@"
    fi
fi

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration with environment variable overrides
REPO_URL="https://github.com/ukkit/llama-chat.git"
INSTALL_DIR="${CHAT_OLLAMA_INSTALL_DIR:-$HOME/llama-chat}"
DEFAULT_PORT="${CHAT_OLLAMA_PORT:-3333}"
LLAMACPP_PORT="${LLAMACPP_PORT:-8120}"

# Model configuration
RECOMMENDED_MODEL="${CHAT_OLLAMA_MODEL:-qwen2.5-0.5b-instruct-q4_0.gguf}"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf"
FALLBACK_MODEL="phi3-mini-4k-instruct-q4.gguf"
FALLBACK_URL="https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"

MIN_PYTHON_VERSION="3.8"

# Non-interactive configuration (environment variables)
AUTO_CONFIRM="${CHAT_OLLAMA_AUTO_CONFIRM:-Y}"
AUTO_DOWNLOAD_MODEL="${CHAT_OLLAMA_DOWNLOAD_MODEL:-Y}"
HANDLE_EXISTING="${CHAT_OLLAMA_HANDLE_EXISTING:-1}"  # 1=remove, 2=update, 3=cancel
AUTO_START="${CHAT_OLLAMA_AUTO_START:-true}"
FORCE_REINSTALL="${CHAT_OLLAMA_FORCE_REINSTALL:-true}"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║      llama-chat 🦙 (llama.cpp)       ║${NC}"
    echo -e "${PURPLE}║      Non-Interactive Installer       ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

# Function to check if command exists (POSIX compatible)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to compare version numbers (POSIX compatible)
version_ge() {
    # Returns 0 (true) if version $1 >= $2
    local ver1="$1"
    local ver2="$2"

    # Convert versions to comparable numbers
    local ver1_major=$(echo "$ver1" | cut -d. -f1)
    local ver1_minor=$(echo "$ver1" | cut -d. -f2 2>/dev/null || echo "0")
    local ver2_major=$(echo "$ver2" | cut -d. -f1)
    local ver2_minor=$(echo "$ver2" | cut -d. -f2 2>/dev/null || echo "0")

    if [ "$ver1_major" -gt "$ver2_major" ]; then
        return 0
    elif [ "$ver1_major" -eq "$ver2_major" ] && [ "$ver1_minor" -ge "$ver2_minor" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get Python version
get_python_version() {
    local python_cmd="$1"
    if command_exists "$python_cmd"; then
        "$python_cmd" -c "import sys; print('.'.join(map(str, sys.version_info[:2])))" 2>/dev/null || echo "0.0"
    else
        echo "0.0"
    fi
}

# Function to check Python installation
check_python() {
    print_step "Checking Python installation..."

    local python_cmd=""
    local python_version=""

    # Try different Python commands
    for cmd in python3 python python3.11 python3.10 python3.9 python3.8; do
        if command_exists "$cmd"; then
            local version=$(get_python_version "$cmd")
            if version_ge "$version" "$MIN_PYTHON_VERSION"; then
                python_cmd="$cmd"
                python_version="$version"
                break
            fi
        fi
    done

    if [ -z "$python_cmd" ]; then
        print_error "Python $MIN_PYTHON_VERSION or higher not found!"
        print_info "Installing Python automatically..."

        if command_exists apt-get; then
            sudo apt update >/dev/null 2>&1 && sudo apt install -y python3 python3-pip python3-venv >/dev/null 2>&1
        elif command_exists yum; then
            sudo yum install -y python3 python3-pip >/dev/null 2>&1
        elif command_exists dnf; then
            sudo dnf install -y python3 python3-pip >/dev/null 2>&1
        elif command_exists brew; then
            brew install python3 >/dev/null 2>&1
        else
            print_error "Cannot install Python automatically."
            print_info "Please install Python $MIN_PYTHON_VERSION+ manually:"
            print_info "• Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip python3-venv"
            print_info "• CentOS/RHEL/Fedora: sudo dnf install python3 python3-pip"
            print_info "• macOS: brew install python3"
            exit 1
        fi

        # Re-check after installation
        python_cmd="python3"
        python_version=$(get_python_version "$python_cmd")

        if [ "$python_version" = "0.0" ]; then
            print_error "Python installation failed"
            exit 1
        fi
    fi

    print_success "Python $python_version found at $(command -v "$python_cmd")"
    echo "PYTHON_CMD=$python_cmd" > /tmp/chat_ollama_env

    # Check if pip is available
    if ! "$python_cmd" -m pip --version >/dev/null 2>&1; then
        print_info "Installing pip..."
        if command_exists apt-get; then
            sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y python3-pip >/dev/null 2>&1
        elif command_exists yum; then
            sudo yum install -y python3-pip >/dev/null 2>&1
        elif command_exists dnf; then
            sudo dnf install -y python3-pip >/dev/null 2>&1
        else
            print_error "pip not found and cannot auto-install. Please install pip manually."
            exit 1
        fi
    fi

    # Check if venv module is available
    if ! "$python_cmd" -m venv --help >/dev/null 2>&1; then
        print_info "Installing venv module..."
        if command_exists apt-get; then
            sudo apt-get install -y python3-venv >/dev/null 2>&1
        else
            print_error "venv module not available. Please install python3-venv package."
            exit 1
        fi
    fi
}

# Function to install llama.cpp
install_llamacpp() {
    print_step "Checking llama.cpp installation..."

    if command_exists llama-server; then
        print_success "llama.cpp already installed at $(command -v llama-server)"
        return 0
    fi

    print_info "Installing llama.cpp..."

    # Try different installation methods based on OS
    if command_exists apt-get; then
        install_llamacpp_debian
    elif command_exists yum || command_exists dnf; then
        install_llamacpp_rhel
    elif command_exists brew; then
        install_llamacpp_macos
    else
        install_llamacpp_source
    fi
}

# Function to install llama.cpp on Debian/Ubuntu
install_llamacpp_debian() {
    print_info "Installing build dependencies for Debian/Ubuntu..."

    # Install build tools
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y build-essential cmake git wget curl >/dev/null 2>&1
    sudo apt-get install -y libssl-dev libopenblas-dev ccache libcurl4-openssl-dev >/dev/null 2>&1

    install_llamacpp_source
}

# Function to install llama.cpp on RHEL/CentOS/Fedora
install_llamacpp_rhel() {
    print_info "Installing build dependencies for RHEL/CentOS/Fedora..."

    # Install build tools
    if command_exists dnf; then
        sudo dnf group install -y "Development Tools" >/dev/null 2>&1
        sudo dnf install -y cmake git wget curl openssl-devel openblas-devel ccache libcurl-devel >/dev/null 2>&1
    else
        sudo yum groupinstall -y "Development Tools" >/dev/null 2>&1
        sudo yum install -y cmake git wget curl openssl-devel openblas-devel ccache libcurl-devel >/dev/null 2>&1
    fi

    install_llamacpp_source
}

# Function to install llama.cpp on macOS
install_llamacpp_macos() {
    print_info "Installing llama.cpp via Homebrew..."

    if brew install llama.cpp >/dev/null 2>&1; then
        print_success "llama.cpp installed via Homebrew"
    else
        print_warning "Homebrew installation failed, trying from source..."
        install_llamacpp_source
    fi
}

# Function to install llama.cpp from source
install_llamacpp_source() {
    print_info "Compiling llama.cpp from source..."

    # Create temporary directory
    local temp_dir="/tmp/llama.cpp.$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # Clone and build llama.cpp from the correct repository
    if git clone https://github.com/ggml-org/llama.cpp.git >/dev/null 2>&1; then
        cd llama.cpp
        mkdir build && cd build

        # Configure and build - basic CPU build
        if cmake -DCMAKE_BUILD_TYPE=Release .. >/dev/null 2>&1 && make -j$(nproc 2>/dev/null || echo "4") >/dev/null 2>&1; then
            # Try to install to system directory
            if sudo cp bin/llama-server /usr/local/bin/ 2>/dev/null; then
                print_success "llama.cpp installed to /usr/local/bin/"
            elif mkdir -p "$HOME/.local/bin" && cp bin/llama-server "$HOME/.local/bin/"; then
                print_success "llama.cpp installed to $HOME/.local/bin/"
                print_info "Make sure $HOME/.local/bin is in your PATH"
                export PATH="$HOME/.local/bin:$PATH"
            else
                print_error "Failed to install llama.cpp binary"
                cd "$INSTALL_DIR"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            print_error "Failed to compile llama.cpp"
            cd "$INSTALL_DIR"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        print_error "Failed to clone llama.cpp repository"
        cd "$INSTALL_DIR"
        rm -rf "$temp_dir"
        return 1
    fi

    # Clean up
    cd "$INSTALL_DIR"
    rm -rf "$temp_dir"

    # Verify installation
    if command_exists llama-server; then
        print_success "llama.cpp installation verified"
        return 0
    else
        print_error "llama-server not found after installation"
        return 1
    fi
}

# Function to check if directory exists and handle it (NON-INTERACTIVE)
check_install_directory() {
    print_step "Checking installation directory..."

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory $INSTALL_DIR already exists"

        # Use environment variable or default behavior
        local choice="$HANDLE_EXISTING"

        case $choice in
            1)
                print_info "Removing existing directory for clean installation..."
                rm -rf "$INSTALL_DIR"
                ;;
            2)
                print_info "Updating existing installation..."
                cd "$INSTALL_DIR"
                if [ -d ".git" ]; then
                    if git pull origin main >/dev/null 2>&1; then
                        print_success "Updated successfully"
                        return 0
                    else
                        print_warning "Update failed, doing clean installation..."
                        cd ..
                        rm -rf "$INSTALL_DIR"
                    fi
                else
                    print_warning "Not a git repository, doing clean installation..."
                    cd ..
                    rm -rf "$INSTALL_DIR"
                fi
                ;;
            3)
                print_info "Installation cancelled by configuration."
                exit 0
                ;;
            *)
                print_info "Using default: removing existing directory..."
                rm -rf "$INSTALL_DIR"
                ;;
        esac
    fi
}

# Function to download llama-chat
download_project() {
    print_step "Downloading llama-chat from GitHub..."

    if ! command_exists git; then
        print_info "Installing git..."

        if command_exists apt-get; then
            sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y git >/dev/null 2>&1
        elif command_exists yum; then
            sudo yum install -y git >/dev/null 2>&1
        elif command_exists dnf; then
            sudo dnf install -y git >/dev/null 2>&1
        elif command_exists brew; then
            brew install git >/dev/null 2>&1
        else
            print_error "Cannot install git automatically. Please install git manually."
            exit 1
        fi
    fi

    # Clone the repository
    if git clone "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1; then
        print_success "llama-chat downloaded successfully"
    else
        print_error "Failed to download llama-chat"
        print_info "You can manually download from: $REPO_URL"
        exit 1
    fi

    cd "$INSTALL_DIR"
}

# Function to create virtual environment
create_virtual_env() {
    print_step "Creating Python virtual environment..."

    # Source Python command from temp file
    source /tmp/chat_ollama_env

    if [ -d "venv" ]; then
        print_info "Removing existing virtual environment..."
        rm -rf venv
    fi

    # Create virtual environment
    if "$PYTHON_CMD" -m venv venv >/dev/null 2>&1; then
        print_success "Virtual environment created"
    else
        print_error "Failed to create virtual environment"
        exit 1
    fi

    # Activate virtual environment
    source venv/bin/activate

    # Upgrade pip
    print_info "Upgrading pip..."
    pip install --upgrade pip >/dev/null 2>&1

    # Install requirements
    print_info "Installing Python dependencies..."
    if [ -f "requirements.txt" ]; then
        if pip install -r requirements.txt >/dev/null 2>&1; then
            print_success "Dependencies installed successfully"
        else
            print_error "Failed to install dependencies"
            exit 1
        fi
    else
        # Fallback installation
        print_warning "requirements.txt not found, installing basic dependencies..."
        pip install Flask==3.0.0 requests==2.31.0 >/dev/null 2>&1
    fi
}

# Function to download models
download_models() {
    print_step "Setting up models directory..."

    # Create models directory
    local models_dir="$INSTALL_DIR/models"
    mkdir -p "$models_dir"

    # Check if any models already exist
    local existing_models=$(find "$models_dir" -name "*.gguf" 2>/dev/null | wc -l)

    if [ "$existing_models" -gt 0 ]; then
        print_success "Found $existing_models existing model(s) in $models_dir"
        find "$models_dir" -name "*.gguf" | while read -r model; do
            local size=$(du -h "$model" 2>/dev/null | cut -f1)
            local basename=$(basename "$model")
            print_info "  • $basename ($size)"
        done
        return 0
    fi

    print_warning "No .gguf models found!"
    print_info "Recommended models for llama-chat:"
    print_info "• $RECOMMENDED_MODEL (~400MB, good performance)"
    print_info "• $FALLBACK_MODEL (~2.3GB, excellent quality)"
    echo ""

    # Use environment variable for auto-download decision
    local download_choice="$AUTO_DOWNLOAD_MODEL"

    case "$download_choice" in
        [Yy]*|""|"true"|"1")  # Y, y, Yes, yes, true, 1, or empty (default)
            print_info "Downloading $RECOMMENDED_MODEL (this may take a few minutes)..."

            local model_path="$models_dir/$RECOMMENDED_MODEL"

            # Try wget first, then curl
            local download_success=false

            if command_exists wget; then
                if wget --progress=bar:force -O "$model_path" "$MODEL_URL" >/dev/null 2>&1; then
                    download_success=true
                fi
            elif command_exists curl; then
                if curl -L --progress-bar -o "$model_path" "$MODEL_URL"; then
                    download_success=true
                fi
            fi

            if [ "$download_success" = true ]; then
                local size=$(du -h "$model_path" 2>/dev/null | cut -f1)
                print_success "Model $RECOMMENDED_MODEL downloaded successfully! ($size)"
            else
                print_warning "Failed to download $RECOMMENDED_MODEL, trying fallback..."
                rm -f "$model_path"

                # Try fallback model
                local fallback_path="$models_dir/$FALLBACK_MODEL"
                local fallback_success=false

                if command_exists wget; then
                    if wget --progress=bar:force -O "$fallback_path" "$FALLBACK_URL" >/dev/null 2>&1; then
                        fallback_success=true
                    fi
                elif command_exists curl; then
                    if curl -L --progress-bar -o "$fallback_path" "$FALLBACK_URL"; then
                        fallback_success=true
                    fi
                fi

                if [ "$fallback_success" = true ]; then
                    local size=$(du -h "$fallback_path" 2>/dev/null | cut -f1)
                    print_success "Fallback model $FALLBACK_MODEL downloaded successfully! ($size)"
                else
                    print_warning "Failed to download any model."
                    rm -f "$fallback_path"
                    print_info "You can download models manually later:"
                    print_info "  ./chat-manager.sh download-model <url> <filename>"
                fi
            fi
            ;;
        *)
            print_info "Skipping model download. You can download models later:"
            print_info "  ./chat-manager.sh download-model <url> <filename>"
            print_info ""
            print_info "Quick download examples:"
            print_info "  ./chat-manager.sh download-model \\"
            print_info "    '$MODEL_URL' \\"
            print_info "    '$RECOMMENDED_MODEL'"
            ;;
    esac
}

# Function to create configuration file
create_config_file() {
    print_step "Creating configuration file..."

    cat > "$INSTALL_DIR/llama-chat.conf" << EOF
# llama-chat Configuration File
# This file contains configuration options for llama-chat and llama.cpp server

# Installation directory
INSTALL_DIR="$INSTALL_DIR"

# Flask application settings
FLASK_HOST="127.0.0.1"
FLASK_PORT="$DEFAULT_PORT"
FLASK_DEBUG="false"

# llama.cpp server settings
LLAMACPP_HOST="127.0.0.1"
LLAMACPP_PORT="$LLAMACPP_PORT"
MODELS_DIR="$INSTALL_DIR/models"

# Model settings
DEFAULT_MODEL=""  # Auto-detect first .gguf file in models directory
CONTEXT_SIZE="4096"
GPU_LAYERS="0"  # Number of layers to offload to GPU (0 = CPU only)
THREADS="$(nproc 2>/dev/null || echo "4")"
BATCH_SIZE="512"

# Advanced llama.cpp server options (environment variables with LLAMA_ARG_ prefix)
# Uncomment and modify as needed:
# LLAMA_ARG_N_PARALLEL="1"           # Number of parallel processing slots
# LLAMA_ARG_CONT_BATCHING="false"    # Enable continuous batching
# LLAMA_ARG_EMBEDDING="false"        # Enable embedding extraction
# LLAMA_ARG_N_THREADS_BATCH="$THREADS"  # Threads for batch processing
# LLAMA_ARG_MLOCK="false"             # Lock model in memory
# LLAMA_ARG_NUMA="false"              # Enable NUMA optimizations

# Security settings
# LLAMA_ARG_API_KEY=""                # API key for request authorization
# LLAMA_ARG_API_KEY_FILE=""           # File containing API keys

# Performance tuning
# LLAMA_ARG_N_CTX="$CONTEXT_SIZE"     # Context size
# LLAMA_ARG_N_BATCH="$BATCH_SIZE"     # Batch size
# LLAMA_ARG_N_UBATCH="512"            # Physical batch size
# LLAMA_ARG_N_KEEP="-1"               # Number of tokens to keep from initial prompt

# Model specific settings
# LLAMA_ARG_ROPE_FREQ_BASE="0.0"      # RoPE base frequency
# LLAMA_ARG_ROPE_FREQ_SCALE="0.0"     # RoPE frequency scaling factor

# Logging
LOG_DIR="$INSTALL_DIR/logs"
LLAMACPP_LOG_FILE="$INSTALL_DIR/logs/llamacpp.log"
FLASK_LOG_FILE="$INSTALL_DIR/logs/flask.log"

EOF

    print_success "Configuration file created at $INSTALL_DIR/llama-chat.conf"
    print_info "You can edit this file to customize your installation"
}

# Function to make scripts executable
setup_permissions() {
    print_step "Setting up permissions..."

    if [ -f "chat-manager.sh" ]; then
        chmod +x chat-manager.sh
        print_success "Made chat-manager.sh executable"
    fi
}

# Function to test installation
test_installation() {
    print_step "Testing installation..."

    # Activate virtual environment
    source venv/bin/activate

    # Check if we can import required modules
    if python -c "import flask, requests; print('Dependencies OK')" >/dev/null 2>&1; then
        print_success "Python dependencies verified"
    else
        print_error "Python dependencies verification failed"
        return 1
    fi

    # Check if llama-server is available
    if command_exists llama-server; then
        print_success "llama.cpp installation verified"
    else
        print_warning "llama-server not found in PATH"
        return 1
    fi

    # Check if models directory exists
    if [ -d "models" ]; then
        local model_count=$(find models -name "*.gguf" 2>/dev/null | wc -l)
        if [ "$model_count" -gt 0 ]; then
            print_success "Found $model_count model file(s)"
        else
            print_warning "No model files found (you can download them later)"
        fi
    fi

    return 0
}

# Function to start llama.cpp server
start_llamacpp_server() {
    print_step "Starting llama.cpp server..."

    # Source configuration if available
    if [ -f "$INSTALL_DIR/llama-chat.conf" ]; then
        source "$INSTALL_DIR/llama-chat.conf"
    fi

    # Find a model file
    local model_file=$(find "$INSTALL_DIR/models" -name "*.gguf" 2>/dev/null | head -n1)

    if [ -z "$model_file" ]; then
        print_warning "No model files found, llama.cpp server cannot start"
        print_info "Download a model first with: ./chat-manager.sh download-model <url> <filename>"
        return 1
    fi

    # Check if port is already in use
    if lsof -i :$LLAMACPP_PORT > /dev/null 2>&1; then
        print_warning "Port $LLAMACPP_PORT already in use, llama.cpp server may already be running"
        return 0
    fi

    print_info "Using model: $(basename "$model_file")"
    print_info "Starting llama.cpp server on port $LLAMACPP_PORT..."

    # Start server in background with configuration
    mkdir -p logs
    nohup llama-server \
        --model "$model_file" \
        --port $LLAMACPP_PORT \
        --host ${LLAMACPP_HOST:-0.0.0.0} \
        --ctx-size ${CONTEXT_SIZE:-4096} \
        --threads ${THREADS:-$(nproc 2>/dev/null || echo "4")} \
        --n-gpu-layers ${GPU_LAYERS:-0} \
        --batch-size ${BATCH_SIZE:-512} \
        > logs/llamacpp.log 2>&1 &

    echo $! > llamacpp.pid

    # Wait for server to start
    local max_attempts=15
    local attempt=1

    print_info "Waiting for llama.cpp server to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://${LLAMACPP_HOST:-127.0.0.1}:$LLAMACPP_PORT/health" >/dev/null 2>&1; then
            print_success "llama.cpp server started successfully!"
            print_info "Server: http://${LLAMACPP_HOST:-127.0.0.1}:$LLAMACPP_PORT"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $max_attempts ]; then
        print_warning "Services may still be starting. Check manually with: ./chat-manager.sh status"
    fi
}

# Function to show final instructions
show_final_instructions() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    🚀 Installation Complete! 🚀${NC}"
    echo -e "${CYAN}    (llama.cpp Edition)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Installation Directory:${NC} $INSTALL_DIR"
    echo -e "${YELLOW}Configuration File:${NC} $INSTALL_DIR/llama-chat.conf"
    if [ "$AUTO_START" = "true" ]; then
        echo -e "${YELLOW}Web Interface:${NC} http://localhost:$DEFAULT_PORT"
        echo -e "${YELLOW}llama.cpp API:${NC} http://${LLAMACPP_HOST:-127.0.0.1}:$LLAMACPP_PORT"
    fi
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo -e "  Edit $INSTALL_DIR/llama-chat.conf to customize settings"
    echo -e "  Key settings: models directory, ports, GPU layers, context size"
    echo ""
    echo -e "${YELLOW}Environment Variables (set before running installer):${NC}"
    echo -e "  export CHAT_OLLAMA_INSTALL_DIR=/custom/path"
    echo -e "  export CHAT_OLLAMA_MODEL=phi3-mini-4k-instruct-q4.gguf"
    echo -e "  export CHAT_OLLAMA_AUTO_START=false"
    echo -e "  export CHAT_OLLAMA_DOWNLOAD_MODEL=false"
    echo -e "  export LLAMACPP_PORT=8080"
    echo ""
    echo -e "${YELLOW}To manage the services:${NC}"
    echo -e "  cd $INSTALL_DIR"
    echo -e "  source venv/bin/activate"
    echo -e "  ./chat-manager.sh [start|stop|status|restart]"
    echo -e "  ./chat-manager.sh start-llamacpp   # Start only llama.cpp"
    echo -e "  ./chat-manager.sh start-flask      # Start only Flask app"
    echo ""
    echo -e "${YELLOW}To download more models:${NC}"
    echo -e "  ./chat-manager.sh download-model \\"
    echo -e "    https://huggingface.co/model.gguf model.gguf"
    echo -e "  ./chat-manager.sh list-models      # Show available models"
    echo ""
    echo -e "${YELLOW}llama.cpp Environment Variables:${NC}"
    echo -e "  All llama-server options can be set via LLAMA_ARG_* variables"
    echo -e "  Example: export LLAMA_ARG_N_GPU_LAYERS=32"
    echo -e "  See configuration file for complete list"
    echo ""
    echo -e "${YELLOW}To update llama-chat:${NC}"
    echo -e "  cd $INSTALL_DIR"
    echo -e "  git pull origin main"
    echo -e "  source venv/bin/activate"
    echo -e "  pip install -r requirements.txt"
    echo -e "  ./chat-manager.sh restart"
    echo ""
    echo -e "${YELLOW}Recommended models to try:${NC}"
    echo -e "  • Qwen2.5-0.5B (~400MB) - Fast, good quality"
    echo -e "  • Phi-3-Mini (~2.3GB) - Excellent quality"
    echo -e "  • Llama-3.2-1B (~1.3GB) - Good balance"
    echo -e "  • Gemma-2-2B (~1.6GB) - Google's efficient model"
    echo ""
    echo -e "${YELLOW}GPU Acceleration:${NC}"
    echo -e "  Edit GPU_LAYERS in llama-chat.conf to enable GPU offloading"
    echo -e "  Set to number of layers (e.g., 32) or -1 for all layers"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  ./chat-manager.sh test              # Test the stack"
    echo -e "  ./chat-manager.sh logs both         # View all logs"
    echo -e "  ./chat-manager.sh info              # System information"
    echo -e "  tail -f logs/llamacpp.log           # llama.cpp server logs"
    echo -e "  tail -f logs/flask.log              # Flask app logs"
    echo ""
    echo -e "${GREEN}Support:${NC} https://github.com/ukkit/llama-chat"
    echo -e "${GREEN}llama.cpp:${NC} https://github.com/ggml-org/llama.cpp"
}

# Function to cleanup on error (POSIX compatible)
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Installation failed with exit code $exit_code. Cleaning up..."

        # Remove temp files
        rm -f /tmp/chat_ollama_env

        # Auto-cleanup partial installation (non-interactive)
        if [ -d "$INSTALL_DIR" ] && [ ! -f "$INSTALL_DIR/.git/config" ]; then
            print_info "Removing partial installation directory..."
            rm -rf "$INSTALL_DIR"
            print_info "Partial installation removed"
        fi
    fi
    exit $exit_code
}

# Set up error handling (POSIX compatible)
handle_error() {
    cleanup_on_error
}

# Main installation function (NON-INTERACTIVE)
main() {
    # Clear screen and show header
    clear
    print_header

    print_info "Non-interactive llama.cpp installation starting..."
    print_info "Installation directory: $INSTALL_DIR"
    print_info "Flask app port: $DEFAULT_PORT"
    print_info "llama.cpp port: $LLAMACPP_PORT"
    print_info "Auto-start: $AUTO_START"
    print_info "Download model: $AUTO_DOWNLOAD_MODEL"
    echo ""
    print_info "Customize with environment variables (see final instructions)"
    echo ""

    # NO USER CONFIRMATION - just start installation
    print_info "Starting installation automatically..."
    echo ""

    # Run installation steps with error handling
    check_python || handle_error
    install_llamacpp || handle_error
    check_install_directory || handle_error

    # Only download if not updating
    if [ ! -d "$INSTALL_DIR" ]; then
        download_project || handle_error
    fi

    cd "$INSTALL_DIR" || handle_error
    create_virtual_env || handle_error
    download_models || handle_error
    create_config_file || handle_error
    setup_permissions || handle_error

    # Test installation
    if test_installation; then
        start_application || handle_error
        show_final_instructions
    else
        print_error "Installation test failed"
        print_info "You may need to troubleshoot manually"
        print_info "Try: ./chat-manager.sh info"
        handle_error
    fi

    # Cleanup temp files
    rm -f /tmp/chat_ollama_env
}

# Check if running as root (warn but don't prevent)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended"
    print_info "Consider running as a regular user for better security"
    echo ""
fi

# Run main installation
main "$@"
        printf "."
    done
    echo

    print_warning "llama.cpp server started but not responding to health checks"
    print_info "Check logs: tail -f logs/llamacpp.log"
    return 1
}

# Function to start the application (OPTIONAL AUTO-START)
start_application() {
    if [ "$AUTO_START" != "true" ]; then
        print_info "Auto-start disabled. Use './chat-manager.sh start' to start the services."
        return 0
    fi

    print_step "Starting llama-chat stack..."

    # Activate virtual environment
    source venv/bin/activate

    # Start llama.cpp server first
    if ! start_llamacpp_server; then
        print_warning "llama.cpp server failed to start, but continuing..."
    fi

    # Find available port for Flask app
    local port=$DEFAULT_PORT
    while lsof -i :$port > /dev/null 2>&1; do
        port=$((port + 1))
    done

    if [ "$port" != "$DEFAULT_PORT" ]; then
        print_warning "Port $DEFAULT_PORT is in use, using port $port instead"
    fi

    # Start the Flask application
    if [ -f "chat-manager.sh" ]; then
        print_info "Starting Flask app with chat-manager.sh..."
        ./chat-manager.sh start-flask "$port" >/dev/null 2>&1 &
    else
        print_info "Starting Flask app manually..."
        mkdir -p logs
        nohup bash -c "PORT=$port python app.py" > logs/llama-chat.log 2>&1 &
        echo $! > process.pid
    fi

    print_info "Waiting for Flask app to start..."
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$port" >/dev/null 2>&1; then
            print_success "llama-chat started successfully!"
            print_success "Web interface: http://localhost:$port"
            print_success "llama.cpp API: http://${LLAMACPP_HOST:-127.0.0.1}:$LLAMACPP_PORT"
            break
        fi

        sleep 2
        attempt=$((attempt + 1))