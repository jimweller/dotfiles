#!/bin/bash

# DevContainer management script - Phase 1 improvements
# Usage: devcontainer.sh [build|b|run|r|connect|c|restart|rt|status|st]

set -euo pipefail

# Configuration with defaults
CONTAINER_NAME="${DEVCONTAINER_NAME:-devcontainer}"
IMAGE_NAME="${DEVCONTAINER_IMAGE:-devcontainer}"
DOCKERFILE_PATH="${DEVCONTAINER_DOCKERFILE_PATH:-./devcontainer}"
HOST_PROJECTS_DIR="${DEVCONTAINER_HOST_PROJECTS:-${HOME}/Projects}"
PORTS="${DEVCONTAINER_PORTS:-3000:3000,3333:3333}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running or accessible"
        exit 1
    fi
}

# Check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to run the devcontainer
run_devcontainer() {
    if container_running; then
        log_warning "Container '$CONTAINER_NAME' is already running"
        return 0
    fi
    
    if container_exists; then
        log_info "Starting existing container..."
        docker start "$CONTAINER_NAME"
        log_success "Container started successfully"
        return 0
    fi
    
    log_info "Creating and starting new container..."
    
    # Parse ports
    local port_args=()
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        port_args+=("-p" "$port")
    done
    
    # Check if host projects directory exists
    if [[ ! -d "$HOST_PROJECTS_DIR" ]]; then
        log_warning "Host projects directory '$HOST_PROJECTS_DIR' does not exist"
        log_info "Creating directory..."
        mkdir -p "$HOST_PROJECTS_DIR"
    fi
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        "${port_args[@]}" \
        --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
        --mount "type=bind,source=${HOST_PROJECTS_DIR},target=/home/vscode/Projects" \
        --user "$(id -u):$(id -g)" \
        --health-cmd="ps aux | grep -v grep | grep -q sleep" \
        --health-interval=30s \
        --health-timeout=3s \
        --health-retries=3 \
        "$IMAGE_NAME"
    
    log_success "Container created and started successfully"
}

# Build the container
build_container() {
    log_info "Building devcontainer image..."
    
    # Stop and remove existing container if running
    if container_running; then
        log_info "Stopping existing container..."
        docker stop "$CONTAINER_NAME"
    fi
    
    if container_exists; then
        log_info "Removing existing container..."
        docker rm "$CONTAINER_NAME"
    fi
    
    local build_args=(
        --build-arg "USER_UID=$(id -u)"
        --build-arg "USER_GID=$(id -g)"
        --progress=plain
        -t "$IMAGE_NAME"
        "$DOCKERFILE_PATH"
    )
    
    if docker build "${build_args[@]}"; then
        log_success "Container built successfully"
        run_devcontainer
    else
        log_error "Failed to build container"
        exit 1
    fi
}

# Connect to the container
connect_container() {
    if ! container_running; then
        log_error "Container '$CONTAINER_NAME' is not running"
        log_info "Use '$0 run' to start the container first"
        exit 1
    fi
    
    log_info "Connecting to container..."
    docker exec -it "$CONTAINER_NAME" /bin/zsh
}

# Show container status
show_status() {
    if container_running; then
        log_success "Container '$CONTAINER_NAME' is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    elif container_exists; then
        log_warning "Container '$CONTAINER_NAME' exists but is not running"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
    else
        log_info "Container '$CONTAINER_NAME' does not exist"
    fi
}

# Restart the container
restart_container() {
    log_info "Restarting container..."
    
    if container_running; then
        log_info "Stopping container..."
        docker stop "$CONTAINER_NAME"
    fi
    
    if container_exists; then
        log_info "Removing container..."
        docker rm "$CONTAINER_NAME"
    fi
    
    run_devcontainer
}

# Show help
show_help() {
    cat << EOF
DevContainer Management Script - Phase 1 Improved

Usage: $0 <command>

Commands:
  build (b)     Build the devcontainer image
  run (r)       Run the devcontainer (create if needed)
  connect (c)   Connect to the running devcontainer
  restart (rt)  Restart the devcontainer
  status (st)   Show container status
  help          Show this help message

Configuration (environment variables):
  DEVCONTAINER_NAME            Container name (default: devcontainer)
  DEVCONTAINER_IMAGE           Image name (default: devcontainer)
  DEVCONTAINER_HOST_PROJECTS   Host projects directory (default: \$HOME/Projects)
  DEVCONTAINER_PORTS           Port mappings (default: 3000:3000,3333:3333)

Examples:
  $0 build                     # Build and start container
  $0 run                       # Start container
  $0 connect                   # Connect with shell
  $0 status                    # Check status

EOF
}

# Main command processing
main() {
    local command="${1:-help}"
    
    case "$command" in
        build|b)
            check_docker
            build_container
            ;;
        run|r)
            check_docker
            run_devcontainer
            ;;
        connect|c)
            check_docker
            connect_container
            ;;
        restart|rt)
            check_docker
            restart_container
            ;;
        status|st)
            check_docker
            show_status
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
