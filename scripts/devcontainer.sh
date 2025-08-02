#!/bin/bash

# DevContainer management script - Phase 1 improvements
# Usage: devcontainer.sh [build|b|run|r|connect|c|restart|rt|status|st]

set -euo pipefail

# Debug configuration
DEBUG="${DEVC_DEBUG:-false}"

# Configuration with defaults
PROJECT_NAME="$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')"
RANDOM_SUFFIX="$(openssl rand -hex 1)"
CONTAINER_NAME="${DEVC_NAME:-devcontainer-${PROJECT_NAME}-${RANDOM_SUFFIX}}"
IMAGE_NAME="${DEVC_IMAGE:-devcontainer}"
DOCKERFILE_PATH="${DEVC_DOCKERFILE_PATH:-${HOME}/dotfiles/devcontainer}"
HOST_PROJECTS_DIR="${DEVC_HOST_PROJECTS:-${HOME}/Projects}"

# Dotfiles configuration
DOTFILES_REPO="${DEVC_DOTFILES_REPO:-https://github.com/jimweller/dotfiles}"
DOTFILES_INSTALL_COMMAND="${DEVC_DOTFILES_INSTALL:-~/dotfiles/install}"
DOTFILES_AUTO_SETUP="${DEVC_DOTFILES_AUTO:-true}"

# Secrets configuration
SECRETS_AUTO_SETUP="${DEVC_SECRETS_AUTO:-true}"
HOST_SECRETS_DIR="${DEVC_SECRETS_DIR:-${HOME}/.secrets}"

# Timeout configuration
DOTFILES_TIMEOUT="${DEVC_DOTFILES_TIMEOUT:-60}"
SECRETS_TIMEOUT="${DEVC_SECRETS_TIMEOUT:-30}"

# Utility functions
debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] $1" >&2
    fi
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Setup dotfiles function
setup_dotfiles_in_container() {
    local container_name="$1"
    
    debug "Starting dotfiles setup for container: $container_name"
    
    # Check if dotfiles already installed
    if docker exec "$container_name" test -f /home/vscode/.dotfiles_installed 2>/dev/null; then
        debug "Dotfiles already installed, skipping"
        return 0
    fi
    
    debug "Cloning and installing dotfiles..."
    # Clone and install dotfiles
    if ! timeout $DOTFILES_TIMEOUT docker exec "$container_name" bash -c "
        if [ ! -d ~/dotfiles ]; then
            git clone $DOTFILES_REPO ~/dotfiles >/dev/null 2>&1
        fi
        if [ -x $DOTFILES_INSTALL_COMMAND ]; then
            cd ~/dotfiles && $DOTFILES_INSTALL_COMMAND >/dev/null 2>&1
        fi
    " 2>/dev/null; then
        debug "Dotfiles installation failed or timed out"
        return 1
    fi
    
    # Unpack secrets if auto-setup enabled
    if [[ "$SECRETS_AUTO_SETUP" == "true" ]]; then
        debug "Secrets auto-setup enabled"
        
        # Check if dotfiles.env exists
        if [[ -f "$HOST_SECRETS_DIR/dotfiles.env" ]]; then
            debug "Loading environment from dotfiles.env..."
            
            # Load environment variables (equivalent to secret dotfiles / loadenv)
            set -a  # automatically export all variables
            if source "$HOST_SECRETS_DIR/dotfiles.env" 2>/dev/null; then
                set +a  # turn off automatic export
                
                debug "Environment loaded - DOTFILES_KEY length: ${#DOTFILES_KEY}, DOTFILES_ARCHIVE: $DOTFILES_ARCHIVE"
                debug "Unpacking secrets with environment variables..."
                
                # Pass specific dotfiles environment variables to container
                local env_args=()
                [[ -n "$DOTFILES_KEY" ]] && env_args+=("--env" "DOTFILES_KEY=$DOTFILES_KEY")
                [[ -n "$DOTFILES_ARCHIVE" ]] && env_args+=("--env" "DOTFILES_ARCHIVE=$DOTFILES_ARCHIVE")
                
                debug "Environment args: ${env_args[*]}"
                
                # Run secrets.sh with environment variables
                if ! timeout $SECRETS_TIMEOUT docker exec "${env_args[@]}" "$container_name" bash -c "
                    echo 'Container env check - Key length:' \${#DOTFILES_KEY} 'Archive:' \$DOTFILES_ARCHIVE
                    SECRETS_SCRIPT=~/dotfiles/scripts/secrets.sh
                    if [[ -x \$SECRETS_SCRIPT ]]; then
                        echo 'Running secrets.sh...'
                        \$SECRETS_SCRIPT open </dev/null >/dev/null 2>&1
                    else
                        echo 'secrets.sh not found or not executable at' \$SECRETS_SCRIPT
                        ls -la ~/dotfiles/scripts/ 2>/dev/null || echo 'scripts directory not found'
                    fi
                " 2>/dev/null; then
                    debug "Secrets unpacking failed or timed out (this is optional)"
                fi
            else
                set +a  # make sure to turn off automatic export even on failure
                debug "Failed to load environment from dotfiles.env"
            fi
        else
            debug "No dotfiles.env found, skipping secrets"
        fi
    fi
    
    debug "Marking dotfiles as installed"
    # Mark dotfiles as installed
    docker exec "$container_name" bash -c "touch ~/.dotfiles_installed" 2>/dev/null || true
    debug "Dotfiles setup completed"
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
        return 0
    fi
    
    if container_exists; then
        docker start "$CONTAINER_NAME" >/dev/null
        return 0
    fi
    
    # Check if host projects directory exists
    if [[ ! -d "$HOST_PROJECTS_DIR" ]]; then
        mkdir -p "$HOST_PROJECTS_DIR"
    fi
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
        --mount "type=bind,source=$(pwd),target=/workspace" \
        --mount "type=bind,source=${HOST_PROJECTS_DIR},target=/home/vscode/Projects" \
        --user "$(id -u):$(id -g)" \
        --workdir="/workspace" \
        --health-cmd="ps aux | grep -v grep | grep -q sleep" \
        --health-interval=30s \
        --health-timeout=3s \
        --health-retries=3 \
        "$IMAGE_NAME" >/dev/null
}

# Build the container
build_container() {
    local no_cache="${1:-false}"
    
    # Stop and remove existing container if running
    if container_running; then
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    if container_exists; then
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    local build_args=(
        --build-arg "USER_UID=$(id -u)"
        --build-arg "USER_GID=$(id -g)"
        --progress=plain
    )
    
    if [[ "$no_cache" == "true" ]]; then
        build_args+=(--no-cache)
    fi
    
    build_args+=(-t "$IMAGE_NAME" "$DOCKERFILE_PATH")
    
    if ! docker build "${build_args[@]}"; then
        log_error "Failed to build container"
        exit 1
    fi
}

# Rebuild the container from scratch
rebuild_container() {
    # Remove existing image if it exists (this is the extra cleanup step for rebuild)
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME" >/dev/null 2>&1
    fi
    
    # Call build_container with no-cache flag
    build_container "true"
}

# Connect to the container with a new interactive instance
connect_container() {
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        log_error "Image '$IMAGE_NAME' not found. Build it first with: $0 build"
        exit 1
    fi
    
    # Check if host projects directory exists
    if [[ ! -d "$HOST_PROJECTS_DIR" ]]; then
        mkdir -p "$HOST_PROJECTS_DIR"
    fi
    
    # Create a temporary container for dotfiles setup if auto-setup enabled
    if [[ "$DOTFILES_AUTO_SETUP" == "true" && -n "$DOTFILES_REPO" ]]; then
        # Start temporary container to check/setup dotfiles
        temp_container="temp-${CONTAINER_NAME}"
        
        # Build docker run command for temporary container
        temp_run_args=(
            -d --name "$temp_container"
            --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode"
            --user "$(id -u):$(id -g)"
            "$IMAGE_NAME"
        )
        
        docker run "${temp_run_args[@]}" >/dev/null 2>&1
        
        # Setup dotfiles in temp container
        setup_dotfiles_in_container "$temp_container"
        
        # Clean up temp container
        docker rm -f "$temp_container" >/dev/null 2>&1
    fi
    
    # Start a new interactive container instance, overriding the ENTRYPOINT
    docker run -it --rm \
        --entrypoint="" \
        --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
        --mount "type=bind,source=$(pwd),target=/workspace" \
        --mount "type=bind,source=${HOST_PROJECTS_DIR},target=/home/vscode/Projects" \
        --user "$(id -u):$(id -g)" \
        --workdir="/workspace" \
        "$IMAGE_NAME" /bin/zsh
}

# Show container status
show_status() {
    if container_running; then
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
    elif container_exists; then
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
    fi
}

# Restart the container
restart_container() {
    if container_running; then
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    if container_exists; then
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    run_devcontainer
}

# Clean up unused Docker resources
cleanup_docker() {
    echo "Cleaning up unused Docker resources..."
    echo "- Removing unused volumes:"
    docker volume prune -f
    echo "- Removing unused containers:"
    docker container prune -f
    echo "- Removing unused images:"
    docker image prune -f
    echo "- Removing unused networks:"
    docker network prune -f
    echo "Docker cleanup completed"
}

# Show help
show_help() {
    cat << EOF
DevContainer Management Script - Phase 1 Improved

Usage: $0 <command>

Commands:
  build (b)     Build the devcontainer image
  rebuild (rb)  Rebuild the devcontainer from scratch (no cache)
  run (r)       Run the devcontainer in background (daemon mode)
  connect (c)   Start a new interactive container instance
  restart (rt)  Restart the background devcontainer
  status (st)   Show container status
  cleanup (cl)  Clean up unused Docker resources (volumes, containers, images)
  help          Show this help message

Configuration (environment variables):
  DEVC_DEBUG                   Enable debug output (default: false)
  DEVC_NAME                    Container name (default: devcontainer-<project>-<xx>)
  DEVC_IMAGE                   Image name (default: devcontainer)
  DEVC_DOCKERFILE_PATH         Dockerfile directory (default: \$HOME/dotfiles/devcontainer)
  DEVC_HOST_PROJECTS          Host projects directory (default: \$HOME/Projects)
  DEVC_DOTFILES_REPO          Dotfiles git repository (default: https://github.com/jimweller/dotfiles)
  DEVC_DOTFILES_INSTALL       Install command (default: ~/dotfiles/install)
  DEVC_DOTFILES_AUTO          Auto-setup dotfiles (default: true)
  DEVC_DOTFILES_TIMEOUT       Dotfiles installation timeout in seconds (default: 60)
  DEVC_SECRETS_AUTO           Auto-setup secrets via secrets.sh (default: true)
  DEVC_SECRETS_TIMEOUT        Secrets unpacking timeout in seconds (default: 30)
  DEVC_SECRETS_DIR            Host secrets directory (default: \$HOME/.secrets)

Note: Container names automatically include the current directory name plus a random
2-character suffix for uniqueness. Each gets its own container instance and volume.
Dotfiles are automatically installed on first connect unless DEVC_DOTFILES_AUTO=false.
Secrets are automatically unpacked after dotfiles installation using secrets.sh if DEVC_SECRETS_AUTO=true (default).
For secrets to work, you need the 'secret' command available on the host and a dotfiles.env file in DEVC_SECRETS_DIR.
The script uses 'secret dotfiles' to source environment variables, then passes them to the container.
Enable debug output with DEVC_DEBUG=true to troubleshoot setup issues.

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
        rebuild|rb)
            check_docker
            rebuild_container
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
        cleanup|cl)
            check_docker
            cleanup_docker
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
