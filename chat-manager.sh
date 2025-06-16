#!/bin/bash

# llama-chat Management Script
# Enhanced version with configuration file support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/cm.conf"

# Load configuration if available
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Default values (can be overridden by config file)
INSTALL_DIR="${INSTALL_DIR:-$SCRIPT_DIR}"
MODELS_DIR="${MODELS_DIR:-$INSTALL_DIR/models}"
LOG_DIR="${LOG_DIR:-$INSTALL_DIR/logs}"
LLAMACPP_PORT="${LLAMACPP_PORT:-8120}"
LLAMACPP_HOST="${LLAMACPP_HOST:-127.0.0.1}"
FLASK_PORT="${FLASK_PORT:-3333}"
FLASK_HOST="${FLASK_HOST:-127.0.0.1}"
CONTEXT_SIZE="${CONTEXT_SIZE:-4096}"
GPU_LAYERS="${GPU_LAYERS:-0}"
THREADS="${THREADS:-$(nproc 2>/dev/null || echo "4")}"
BATCH_SIZE="${BATCH_SIZE:-512}"

# PID files
LLAMACPP_PID_FILE="$INSTALL_DIR/llamacpp.pid"
FLASK_PID_FILE="$INSTALL_DIR/flask.pid"

# Log files
LLAMACPP_LOG_FILE="${LLAMACPP_LOG_FILE:-$LOG_DIR/llamacpp.log}"
FLASK_LOG_FILE="${FLASK_LOG_FILE:-$LOG_DIR/flask.log}"

# Function to print colored output
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

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         llama-chat Manager           ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    local port="$1"
    if command_exists lsof; then
        lsof -i ":$port" >/dev/null 2>&1
    elif command_exists netstat; then
        netstat -ln | grep ":$port " >/dev/null 2>&1
    else
        # Fallback: try to connect
        timeout 1 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null
    fi
}

# Function to get process status
get_process_status() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}●${NC} $service_name (PID: $pid) - ${GREEN}Running${NC}"
            return 0
        else
            echo -e "${RED}●${NC} $service_name - ${RED}Dead (stale PID file)${NC}"
            rm -f "$pid_file"
            return 1
        fi
    else
        echo -e "${RED}●${NC} $service_name - ${RED}Not running${NC}"
        return 1
    fi
}

# Function to find model file
find_model_file() {
    if [ -n "$DEFAULT_MODEL" ] && [ -f "$MODELS_DIR/$DEFAULT_MODEL" ]; then
        echo "$MODELS_DIR/$DEFAULT_MODEL"
        return 0
    fi

    # Auto-detect first .gguf file
    local model_file=$(find "$MODELS_DIR" -name "*.gguf" 2>/dev/null | head -n1)
    if [ -n "$model_file" ]; then
        echo "$model_file"
        return 0
    fi

    return 1
}

# Function to start llama.cpp server
start_llamacpp() {
    print_step "Starting llama.cpp server..."

    # Check if already running
    if get_process_status "$LLAMACPP_PID_FILE" "llama-server" >/dev/null; then
        print_warning "llama.cpp server is already running"
        return 0
    fi

    # Check if port is in use
    if port_in_use "$LLAMACPP_PORT"; then
        print_error "Port $LLAMACPP_PORT is already in use"
        return 1
    fi

    # Find model file
    local model_file
    if ! model_file=$(find_model_file); then
        print_error "No model files found in $MODELS_DIR"
        print_info "Download a model first with: $0 download-model <url> <filename>"
        return 1
    fi

    print_info "Using model: $(basename "$model_file")"
    print_info "Starting on $LLAMACPP_HOST:$LLAMACPP_PORT with $GPU_LAYERS GPU layers"

    # Create logs directory
    mkdir -p "$LOG_DIR"

    # Build llama-server command with environment variables
    local cmd="llama-server"
    cmd="$cmd --model '$model_file'"
    cmd="$cmd --host '$LLAMACPP_HOST'"
    cmd="$cmd --port '$LLAMACPP_PORT'"
    cmd="$cmd --ctx-size '$CONTEXT_SIZE'"
    cmd="$cmd --threads '$THREADS'"
    cmd="$cmd --batch-size '$BATCH_SIZE'"
    cmd="$cmd --n-gpu-layers '$GPU_LAYERS'"

    # Start server in background
    nohup bash -c "$cmd" > "$LLAMACPP_LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$LLAMACPP_PID_FILE"

    # Wait for server to start
    local max_attempts=15
    local attempt=1

    print_info "Waiting for server to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://$LLAMACPP_HOST:$LLAMACPP_PORT/health" >/dev/null 2>&1; then
            print_success "llama.cpp server started successfully!"
            print_info "API endpoint: http://$LLAMACPP_HOST:$LLAMACPP_PORT"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        printf "."
    done
    echo ""

    print_error "Server failed to start or is not responding"
    print_info "Check logs: tail -f $LLAMACPP_LOG_FILE"
    return 1
}

# Function to start Flask application
start_flask() {
    print_step "Starting Flask application..."

    # Check if already running
    if get_process_status "$FLASK_PID_FILE" "Flask app" >/dev/null; then
        print_warning "Flask application is already running"
        return 0
    fi

    # Check if port is in use
    if port_in_use "$FLASK_PORT"; then
        print_error "Port $FLASK_PORT is already in use"
        return 1
    fi

    # Check if virtual environment exists
    if [ ! -d "$INSTALL_DIR/venv" ]; then
        print_error "Virtual environment not found at $INSTALL_DIR/venv"
        print_info "Run the installer first or create virtual environment manually"
        return 1
    fi

    # Create logs directory
    mkdir -p "$LOG_DIR"

    # Start Flask app
    cd "$INSTALL_DIR"
    nohup bash -c "
        source venv/bin/activate
        export FLASK_HOST='$FLASK_HOST'
        export FLASK_PORT='$FLASK_PORT'
        export LLAMACPP_HOST='$LLAMACPP_HOST'
        export LLAMACPP_PORT='$LLAMACPP_PORT'
        python app.py
    " > "$FLASK_LOG_FILE" 2>&1 &

    local pid=$!
    echo "$pid" > "$FLASK_PID_FILE"

    # Wait for Flask to start
    local max_attempts=10
    local attempt=1

    print_info "Waiting for Flask app to start..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://$FLASK_HOST:$FLASK_PORT" >/dev/null 2>&1; then
            print_success "Flask application started successfully!"
            print_info "Web interface: http://$FLASK_HOST:$FLASK_PORT"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        printf "."
    done
    echo ""

    print_warning "Flask app may still be starting"
    print_info "Check logs: tail -f $FLASK_LOG_FILE"
    return 1
}

# Function to stop a service
stop_service() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_info "Stopping $service_name (PID: $pid)..."
            kill "$pid"

            # Wait for process to stop
            local attempt=1
            while [ $attempt -le 10 ] && ps -p "$pid" > /dev/null 2>&1; do
                sleep 1
                attempt=$((attempt + 1))
            done

            # Force kill if still running
            if ps -p "$pid" > /dev/null 2>&1; then
                print_warning "Process didn't stop gracefully, force killing..."
                kill -9 "$pid" 2>/dev/null || true
            fi

            rm -f "$pid_file"
            print_success "$service_name stopped"
        else
            print_warning "$service_name was not running (removing stale PID file)"
            rm -f "$pid_file"
        fi
    else
        print_info "$service_name is not running"
    fi
}

# Function to show status
show_status() {
    print_header
    echo "Service Status:"
    echo "==============="

    get_process_status "$LLAMACPP_PID_FILE" "llama-server"
    local llamacpp_running=$?

    get_process_status "$FLASK_PID_FILE" "Flask app"
    local flask_running=$?

    echo ""
    echo "Configuration:"
    echo "=============="
    echo "Install Directory: $INSTALL_DIR"
    echo "Models Directory:  $MODELS_DIR"
    echo "Config File:       $CONFIG_FILE"
    echo "llama.cpp API:     http://$LLAMACPP_HOST:$LLAMACPP_PORT"
    echo "Flask Web UI:      http://$FLASK_HOST:$FLASK_PORT"
    echo "GPU Layers:        $GPU_LAYERS"
    echo "Context Size:      $CONTEXT_SIZE"
    echo "Threads:           $THREADS"

    echo ""
    echo "Models:"
    echo "======="
    if [ -d "$MODELS_DIR" ]; then
        local model_count=$(find "$MODELS_DIR" -name "*.gguf" 2>/dev/null | wc -l)
        if [ "$model_count" -gt 0 ]; then
            find "$MODELS_DIR" -name "*.gguf" | while read -r model; do
                local size=$(du -h "$model" 2>/dev/null | cut -f1)
                local basename=$(basename "$model")
                echo "  • $basename ($size)"
            done
        else
            echo "  No .gguf models found"
        fi
    else
        echo "  Models directory not found: $MODELS_DIR"
    fi

    echo ""
    echo "Recent Logs:"
    echo "============"
    if [ -f "$LLAMACPP_LOG_FILE" ] && [ $llamacpp_running -eq 0 ]; then
        echo "llama.cpp (last 3 lines):"
        tail -n 3 "$LLAMACPP_LOG_FILE" 2>/dev/null | sed 's/^/  /' || echo "  No logs available"
    fi

    if [ -f "$FLASK_LOG_FILE" ] && [ $flask_running -eq 0 ]; then
        echo "Flask (last 3 lines):"
        tail -n 3 "$FLASK_LOG_FILE" 2>/dev/null | sed 's/^/  /' || echo "  No logs available"
    fi
}

# Function to download model
download_model() {
    local url="$1"
    local filename="$2"

    if [ -z "$url" ] || [ -z "$filename" ]; then
        print_error "Usage: $0 download-model <url> <filename>"
        echo ""
        echo "Examples:"
        echo "  $0 download-model \\"
        echo "    'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf' \\"
        echo "    'qwen2.5-0.5b-instruct-q4_0.gguf'"
        echo ""
        echo "  $0 download-model \\"
        echo "    'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf' \\"
        echo "    'phi3-mini-4k-instruct-q4.gguf'"
        return 1
    fi

    mkdir -p "$MODELS_DIR"
    local model_path="$MODELS_DIR/$filename"

    if [ -f "$model_path" ]; then
        print_warning "Model file already exists: $filename"
        local size=$(du -h "$model_path" 2>/dev/null | cut -f1)
        print_info "Existing file size: $size"
        read -p "Overwrite? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Download cancelled"
            return 0
        fi
    fi

    print_step "Downloading $filename..."
    print_info "URL: $url"
    print_info "Destination: $model_path"

    # Try wget first, then curl
    if command_exists wget; then
        if wget --progress=bar:force -O "$model_path" "$url"; then
            local size=$(du -h "$model_path" 2>/dev/null | cut -f1)
            print_success "Downloaded successfully! Size: $size"
            return 0
        else
            print_error "Download failed with wget"
            rm -f "$model_path"
            return 1
        fi
    elif command_exists curl; then
        if curl -L --progress-bar -o "$model_path" "$url"; then
            local size=$(du -h "$model_path" 2>/dev/null | cut -f1)
            print_success "Downloaded successfully! Size: $size"
            return 0
        else
            print_error "Download failed with curl"
            rm -f "$model_path"
            return 1
        fi
    else
        print_error "Neither wget nor curl found. Please install one of them."
        return 1
    fi
}

# Function to list models
list_models() {
    print_step "Available models in $MODELS_DIR:"
    echo ""

    if [ ! -d "$MODELS_DIR" ]; then
        print_warning "Models directory not found: $MODELS_DIR"
        return 1
    fi

    local model_count=$(find "$MODELS_DIR" -name "*.gguf" 2>/dev/null | wc -l)

    if [ "$model_count" -eq 0 ]; then
        print_warning "No .gguf model files found"
        echo ""
        echo "To download models, use:"
        echo "  $0 download-model <url> <filename>"
        return 1
    fi

    echo "Found $model_count model(s):"
    echo ""

    find "$MODELS_DIR" -name "*.gguf" | sort | while read -r model; do
        local size=$(du -h "$model" 2>/dev/null | cut -f1)
        local basename=$(basename "$model")
        local modified=$(stat -c %y "$model" 2>/dev/null | cut -d' ' -f1)
        echo "  📄 $basename"
        echo "     Size: $size, Modified: $modified"
        echo "     Path: $model"
        echo ""
    done
}

# Function to show logs
show_logs() {
    local service="$1"
    local lines="${2:-50}"

    case "$service" in
        "llamacpp"|"llama"|"server")
            if [ -f "$LLAMACPP_LOG_FILE" ]; then
                print_info "llama.cpp server logs (last $lines lines):"
                tail -n "$lines" "$LLAMACPP_LOG_FILE"
            else
                print_warning "llama.cpp log file not found: $LLAMACPP_LOG_FILE"
            fi
            ;;
        "flask"|"web"|"app")
            if [ -f "$FLASK_LOG_FILE" ]; then
                print_info "Flask application logs (last $lines lines):"
                tail -n "$lines" "$FLASK_LOG_FILE"
            else
                print_warning "Flask log file not found: $FLASK_LOG_FILE"
            fi
            ;;
        "both"|"all"|"")
            echo "=== llama.cpp server logs ==="
            if [ -f "$LLAMACPP_LOG_FILE" ]; then
                tail -n "$lines" "$LLAMACPP_LOG_FILE"
            else
                print_warning "llama.cpp log file not found"
            fi
            echo ""
            echo "=== Flask application logs ==="
            if [ -f "$FLASK_LOG_FILE" ]; then
                tail -n "$lines" "$FLASK_LOG_FILE"
            else
                print_warning "Flask log file not found"
            fi
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: llamacpp, flask, both"
            return 1
            ;;
    esac
}

# Function to follow logs
follow_logs() {
    local service="$1"

    case "$service" in
        "llamacpp"|"llama"|"server")
            if [ -f "$LLAMACPP_LOG_FILE" ]; then
                print_info "Following llama.cpp server logs (Ctrl+C to stop):"
                tail -f "$LLAMACPP_LOG_FILE"
            else
                print_warning "llama.cpp log file not found: $LLAMACPP_LOG_FILE"
            fi
            ;;
        "flask"|"web"|"app")
            if [ -f "$FLASK_LOG_FILE" ]; then
                print_info "Following Flask application logs (Ctrl+C to stop):"
                tail -f "$FLASK_LOG_FILE"
            else
                print_warning "Flask log file not found: $FLASK_LOG_FILE"
            fi
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: llamacpp, flask"
            return 1
            ;;
    esac
}

# Function to test installation
test_installation() {
    print_header
    echo "Testing llama-chat installation..."
    echo ""

    local errors=0

    # Test 1: Check directories
    print_step "Checking directories..."
    for dir in "$INSTALL_DIR" "$MODELS_DIR" "$LOG_DIR"; do
        if [ -d "$dir" ]; then
            print_success "Directory exists: $dir"
        else
            print_error "Directory missing: $dir"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Check configuration
    print_step "Checking configuration..."
    if [ -f "$CONFIG_FILE" ]; then
        print_success "Configuration file found: $CONFIG_FILE"
    else
        print_warning "Configuration file not found: $CONFIG_FILE"
    fi

    # Test 3: Check virtual environment
    print_step "Checking virtual environment..."
    if [ -d "$INSTALL_DIR/venv" ]; then
        print_success "Virtual environment found"

        # Test Python dependencies
        if source "$INSTALL_DIR/venv/bin/activate" && python -c "import flask, requests" 2>/dev/null; then
            print_success "Python dependencies available"
        else
            print_error "Python dependencies missing"
            errors=$((errors + 1))
        fi
    else
        print_error "Virtual environment not found"
        errors=$((errors + 1))
    fi

    # Test 4: Check llama-server
    print_step "Checking llama.cpp installation..."
    if command_exists llama-server; then
        print_success "llama-server found at $(command -v llama-server)"
    else
        print_error "llama-server not found in PATH"
        errors=$((errors + 1))
    fi

    # Test 5: Check models
    print_step "Checking models..."
    local model_count=$(find "$MODELS_DIR" -name "*.gguf" 2>/dev/null | wc -l)
    if [ "$model_count" -gt 0 ]; then
        print_success "Found $model_count model file(s)"
    else
        print_warning "No model files found (you can download them later)"
    fi

    # Test 6: Check ports
    print_step "Checking port availability..."
    if port_in_use "$LLAMACPP_PORT"; then
        print_warning "llama.cpp port $LLAMACPP_PORT is in use"
    else
        print_success "llama.cpp port $LLAMACPP_PORT is available"
    fi

    if port_in_use "$FLASK_PORT"; then
        print_warning "Flask port $FLASK_PORT is in use"
    else
        print_success "Flask port $FLASK_PORT is available"
    fi

    echo ""
    if [ $errors -eq 0 ]; then
        print_success "All tests passed! Installation looks good."
        echo ""
        echo "Next steps:"
        echo "  • Start services: $0 start"
        echo "  • Check status: $0 status"
        echo "  • Download models: $0 download-model <url> <filename>"
    else
        print_error "Found $errors error(s). Please fix them before using llama-chat."
    fi
}

# Function to show system info
show_info() {
    print_header
    echo "System Information:"
    echo "==================="

    # Basic system info
    echo "OS: $(uname -s) $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU cores: $(nproc 2>/dev/null || echo "unknown")"

    # Memory info
    if command_exists free; then
        local mem_info=$(free -h | grep '^Mem:')
        echo "Memory: $(echo "$mem_info" | awk '{print $2 " total, " $3 " used, " $7 " available"}')"
    fi

    # Disk space
    if [ -d "$INSTALL_DIR" ]; then
        local disk_info=$(df -h "$INSTALL_DIR" | tail -n1)
        echo "Disk (install dir): $(echo "$disk_info" | awk '{print $4 " available of " $2 " total"}')"
    fi

    echo ""
    echo "Software Information:"
    echo "====================="

    # Python version
    if command_exists python3; then
        echo "Python: $(python3 --version 2>&1)"
    else
        echo "Python: Not found"
    fi

    # Git version
    if command_exists git; then
        echo "Git: $(git --version)"
    else
        echo "Git: Not found"
    fi

    # curl/wget
    if command_exists curl; then
        echo "curl: $(curl --version | head -n1)"
    elif command_exists wget; then
        echo "wget: $(wget --version | head -n1)"
    else
        echo "Download tools: None found"
    fi

    # llama-server
    if command_exists llama-server; then
        echo "llama-server: Found at $(command -v llama-server)"
    else
        echo "llama-server: Not found"
    fi

    echo ""
    echo "GPU Information:"
    echo "================"

    # NVIDIA GPU
    if command_exists nvidia-smi; then
        echo "NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader,nounits | \
            awk -F', ' '{printf "  %s (%s MB total, %s MB used)\n", $1, $2, $3}'
    else
        echo "NVIDIA GPU: Not detected or nvidia-smi not available"
    fi

    # AMD GPU
    if command_exists rocm-smi; then
        echo "AMD GPU detected (ROCm):"
        rocm-smi --showproductname --showmeminfo vram | grep -E "(Card|Memory)" || echo "  Could not get GPU info"
    else
        echo "AMD GPU: Not detected or rocm-smi not available"
    fi

    # Intel GPU
    if command_exists intel_gpu_top; then
        echo "Intel GPU: Detected"
    else
        echo "Intel GPU: Not detected or intel_gpu_top not available"
    fi

    echo ""
    echo "Configuration:"
    echo "=============="
    echo "Install Directory: $INSTALL_DIR"
    echo "Models Directory: $MODELS_DIR"
    echo "Config File: $CONFIG_FILE"
    echo "llama.cpp Host: $LLAMACPP_HOST"
    echo "llama.cpp Port: $LLAMACPP_PORT"
    echo "Flask Host: $FLASK_HOST"
    echo "Flask Port: $FLASK_PORT"
    echo "GPU Layers: $GPU_LAYERS"
    echo "Context Size: $CONTEXT_SIZE"
    echo "Threads: $THREADS"
    echo "Batch Size: $BATCH_SIZE"
}

# Function to show help
show_help() {
    print_header
    echo "llama-chat Management Script"
    echo ""
    echo "USAGE:"
    echo "  $0 <command> [options]"
    echo ""
    echo "COMMANDS:"
    echo "  start                 Start both llama.cpp server and Flask app"
    echo "  stop                  Stop both services"
    echo "  restart               Restart both services"
    echo "  status                Show service status and configuration"
    echo ""
    echo "  start-llamacpp        Start only llama.cpp server"
    echo "  start-flask           Start only Flask application"
    echo "  stop-llamacpp         Stop only llama.cpp server"
    echo "  stop-flask            Stop only Flask application"
    echo ""
    echo "  download-model <url> <filename>  Download a model file"
    echo "  list-models           List downloaded models"
    echo ""
    echo "  logs [service] [lines]           Show recent logs"
    echo "    service: llamacpp, flask, both (default: both)"
    echo "    lines: number of lines to show (default: 50)"
    echo ""
    echo "  follow [service]      Follow logs in real-time"
    echo "    service: llamacpp, flask"
    echo ""
    echo "  test                  Test installation"
    echo "  info                  Show system information"
    echo "  help                  Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 start              # Start all services"
    echo "  $0 status             # Check what's running"
    echo "  $0 logs llamacpp 100  # Show last 100 lines of llama.cpp logs"
    echo "  $0 follow flask       # Follow Flask logs"
    echo "  $0 download-model \\"
    echo "    'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf' \\"
    echo "    'qwen2.5-0.5b-instruct-q4_0.gguf'"
    echo ""
    echo "CONFIGURATION:"
    echo "  Edit $CONFIG_FILE to customize settings"
    echo "  Key settings: ports, model directory, GPU layers, context size"
}

# Main script logic
main() {
    local command="${1:-help}"

    case "$command" in
        "start")
            start_llamacpp
            start_flask
            ;;
        "stop")
            stop_service "$FLASK_PID_FILE" "Flask app"
            stop_service "$LLAMACPP_PID_FILE" "llama-server"
            ;;
        "restart")
            stop_service "$FLASK_PID_FILE" "Flask app"
            stop_service "$LLAMACPP_PID_FILE" "llama-server"
            sleep 2
            start_llamacpp
            start_flask
            ;;
        "start-llamacpp"|"start-llama"|"start-server")
            start_llamacpp
            ;;
        "start-flask"|"start-web"|"start-app")
            start_flask
            ;;
        "stop-llamacpp"|"stop-llama"|"stop-server")
            stop_service "$LLAMACPP_PID_FILE" "llama-server"
            ;;
        "stop-flask"|"stop-web"|"stop-app")
            stop_service "$FLASK_PID_FILE" "Flask app"
            ;;
        "status")
            show_status
            ;;
        "download-model")
            download_model "$2" "$3"
            ;;
        "list-models"|"models")
            list_models
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "follow")
            follow_logs "$2"
            ;;
        "test")
            test_installation
            ;;
        "info")
            show_info
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"