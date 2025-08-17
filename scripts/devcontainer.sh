#!/bin/bash

# 0jimbox management script - Phase 1 improvements
# Usage: devcontainer.sh [build|b|run|r|connect|c|restart|rt|status|st]

set -euo pipefail

# Debug configuration
DEBUG="${DEVC_DEBUG:-false}"

# Configuration with defaults
PROJECT_NAME="$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')"
RANDOM_SUFFIX="$(openssl rand -hex 1)"
CONTAINER_NAME="${DEVC_NAME:-0jimbox-${PROJECT_NAME}-${RANDOM_SUFFIX}}"
IMAGE_NAME="${DEVC_IMAGE:-0jimbox}"
DOCKERFILE_PATH="${DEVC_DOCKERFILE_PATH:-${HOME}/.config/dotfiles/devcontainer}"

# Dotfiles configuration
DOTFILES_REPO="${DEVC_DOTFILES_REPO:-https://github.com/jimweller/dotfiles}"
DOTFILES_INSTALL_COMMAND="${DEVC_DOTFILES_INSTALL:-~/.config/dotfiles/install}"
DOTFILES_AUTO_SETUP="${DEVC_DOTFILES_AUTO:-true}"

# Secrets configuration
SECRETS_AUTO_SETUP="${DEVC_SECRETS_AUTO:-true}"
HOST_SECRETS_DIR="${DEVC_SECRETS_DIR:-${HOME}/.secrets}"
SECRETS_ENV_FILE="${DEVC_SECRETS_ENV:-dotfiles.env}"

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
        if [ ! -d ~/.config/dotfiles ]; then
            git clone $DOTFILES_REPO ~/.config/dotfiles >/dev/null 2>&1
        fi
        if [ -x $DOTFILES_INSTALL_COMMAND ]; then
            cd ~/.config/dotfiles && $DOTFILES_INSTALL_COMMAND >/dev/null 2>&1
        fi
    " 2>/dev/null; then
        debug "Dotfiles installation failed or timed out"
        return 1
    fi
    
    # Unpack secrets if auto-setup enabled
    if [[ "$SECRETS_AUTO_SETUP" == "true" ]]; then
        debug "Secrets auto-setup enabled"
        
        # Check if secrets env file exists
        if [[ -f "$HOST_SECRETS_DIR/$SECRETS_ENV_FILE" ]]; then
            debug "Loading environment from $SECRETS_ENV_FILE..."
            
            # Load environment variables (equivalent to secret dotfiles / loadenv)
            set -a  # automatically export all variables
            if source "$HOST_SECRETS_DIR/$SECRETS_ENV_FILE" 2>/dev/null; then
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
                    SECRETS_SCRIPT=~/.config/dotfiles/scripts/secrets.sh
                    if [[ -x \$SECRETS_SCRIPT ]]; then
                        \$SECRETS_SCRIPT open </dev/null >/dev/null 2>&1
                    fi
                " 2>/dev/null; then
                    debug "Secrets unpacking failed or timed out (this is optional)"
                fi
            else
                set +a  # make sure to turn off automatic export even on failure
                debug "Failed to load environment from $SECRETS_ENV_FILE"
            fi
        else
            debug "No $SECRETS_ENV_FILE found, skipping secrets"
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

# Function to run the 0jimbox
run_0jimbox() {
    if container_running; then
        return 0
    fi
    
    if container_exists; then
        docker start "$CONTAINER_NAME" >/dev/null
        return 0
    fi
    
    # Check if host .granted directory exists
    local host_granted_dir="${HOME}/.granted"
    local granted_mounts=""
    
    if [[ -d "$host_granted_dir/secure-storage" ]]; then
        granted_mounts="--mount type=bind,source=$host_granted_dir/secure-storage,target=/home/vscode/.granted/secure-storage"
    fi
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
        --mount "type=bind,source=$(pwd),target=/workspace" \
        $granted_mounts \
        --user "$(id -u):$(id -g)" \
        --workdir="/workspace" \
        --health-cmd="ps aux | grep -v grep | grep -q zsh" \
        --health-interval=30s \
        --health-timeout=3s \
        --health-retries=3 \
        "$IMAGE_NAME" tail -f /dev/null >/dev/null
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
    
    # Check if host .granted directory exists for mount options
    local host_granted_dir="${HOME}/.granted"
    local granted_mounts=""
    
    if [[ -d "$host_granted_dir/secure-storage" ]]; then
        granted_mounts="--mount type=bind,source=$host_granted_dir/secure-storage,target=/home/vscode/.granted/secure-storage"
    fi
    
    # Start a new interactive container instance, overriding the ENTRYPOINT
    docker run -it --rm \
        --entrypoint="" \
        --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
        --mount "type=bind,source=$(pwd),target=/workspace" \
        $granted_mounts \
        --user "$(id -u):$(id -g)" \
        --workdir="/workspace" \
        "$IMAGE_NAME" /bin/zsh
}

# Show container status
show_status() {
    # Show all containers based on 0jimbox image
    local all_containers
    all_containers=$(docker ps -a --filter "ancestor=$IMAGE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null)
    
    if [[ -n "$all_containers" && "$all_containers" != "NAMES	STATUS	IMAGE" ]]; then
        echo "All 0jimbox Container Instances:"
        echo "$all_containers"
        
        # Highlight current project's container if it exists
        if container_exists; then
            echo ""
            echo "Current project container: $CONTAINER_NAME"
        fi
    else
        echo "No containers found based on $IMAGE_NAME image"
        echo "Current project container name would be: $CONTAINER_NAME"
        echo "Use '$0 build' to create the image, then '$0 run' or '$0 connect' to start a container"
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
    
    run_0jimbox
}

# Execute command in container (like connect but runs command instead of interactive shell)
exec_container() {
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        log_error "Image '$IMAGE_NAME' not found. Build it first with: $0 build"
        exit 1
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
    
    # Check if host .granted directory exists for mount options
    local host_granted_dir="${HOME}/.granted"
    local granted_mounts=""
    
    if [[ -d "$host_granted_dir/secure-storage" ]]; then
        granted_mounts="--mount type=bind,source=$host_granted_dir/secure-storage,target=/home/vscode/.granted/secure-storage"
    fi
    
    # Execute command in a new container instance, like connect but run command
    if [[ $# -eq 0 ]]; then
        # No command provided, start interactive shell (same as connect)
        docker run -it --rm \
            --entrypoint="" \
            --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
            --mount "type=bind,source=$(pwd),target=/workspace" \
            $granted_mounts \
            --user "$(id -u):$(id -g)" \
            --workdir="/workspace" \
            "$IMAGE_NAME" /bin/zsh
    else
        # Execute the provided command - use -it for interactive tools like Claude CLI
        docker run -it --rm \
            --entrypoint="" \
            --mount "source=${CONTAINER_NAME}-homedir,target=/home/vscode" \
            --mount "type=bind,source=$(pwd),target=/workspace" \
            $granted_mounts \
            --user "$(id -u):$(id -g)" \
            --workdir="/workspace" \
            "$IMAGE_NAME" "$@"
    fi
}

# Clean up unused Docker resources
cleanup_docker() {
    # Stop and remove all 0jimbox-related containers
    docker ps -a --format '{{.Names}}' | grep -E '(0jimbox|temp-)' | xargs -r docker rm -f 2>/dev/null || true
    
    # Remove all 0jimbox-related volumes
    docker volume ls --format '{{.Name}}' | grep -E '0jimbox' | xargs -r docker volume rm 2>/dev/null || true
    
    # Remove all 0jimbox-related images
    #docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '0jimbox' | xargs -r docker rmi -f 2>/dev/null || true
    
    docker volume prune -f
    docker container prune -f
    docker image prune -f
    docker network prune -f
}

# Install devcontainer structure in current directory
install_devcontainer() {
    local target_dir=".devcontainer"
    local devcontainer_file="$target_dir/devcontainer.json"
    local source_file="$DOCKERFILE_PATH/devcontainer.json"
    
    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        log_error "Source devcontainer.json not found at: $source_file"
        exit 1
    fi
    
    # Check if .devcontainer already exists
    if [[ -d "$target_dir" ]]; then
        echo "Warning: .devcontainer directory already exists in $(pwd)"
        if [[ -f "$devcontainer_file" ]]; then
            echo "Warning: devcontainer.json already exists, skipping installation"
            return 0
        fi
    fi
    
    # Create .devcontainer directory
    mkdir -p "$target_dir"
    
    # Copy devcontainer.json from source
    if cp "$source_file" "$devcontainer_file"; then
        echo "Successfully created .devcontainer structure in $(pwd)"
        echo "Created: $devcontainer_file (copied from $source_file)"
    else
        log_error "Failed to copy devcontainer.json from $source_file"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
0jimbox Management Script - Phase 1 Improved

Usage: $0 <command>

Commands:
  install (i)   Create .devcontainer structure in current directory
  build (b)     Build the 0jimbox image
  rebuild (rb)  Rebuild the 0jimbox from scratch (no cache)
  run (r)       Run the 0jimbox in background (daemon mode)
  connect (c)   Start a new interactive container instance
  exec (e)      Execute command in running container (starts container if needed)
  restart (rt)  Restart the background 0jimbox
  status (st)   Show container status
  cleanup (cl)  Clean up unused Docker resources (volumes, containers, images)
  help          Show this help message

Configuration (environment variables):
  DEVC_DEBUG                   Enable debug output (default: false)
  DEVC_NAME                    Container name (default: 0jimbox-<project>-<xx>)
  DEVC_IMAGE                   Image name (default: 0jimbox)
  DEVC_DOCKERFILE_PATH         Dockerfile directory (default: \$HOME/.config/dotfiles/devcontainer)
  DEVC_DOTFILES_REPO          Dotfiles git repository (default: https://github.com/jimweller/dotfiles)
  DEVC_DOTFILES_INSTALL       Install command (default: ~/.config/dotfiles/install)
  DEVC_DOTFILES_AUTO          Auto-setup dotfiles (default: true)
  DEVC_DOTFILES_TIMEOUT       Dotfiles installation timeout in seconds (default: 60)
  DEVC_SECRETS_AUTO           Auto-setup secrets via secrets.sh (default: true)
  DEVC_SECRETS_TIMEOUT        Secrets unpacking timeout in seconds (default: 30)
  DEVC_SECRETS_DIR            Host secrets directory (default: \$HOME/.secrets)
  DEVC_SECRETS_ENV            Secrets environment file name (default: dotfiles.env)

Note: Container names automatically include the current directory name plus a random
2-character suffix for uniqueness. Each gets its own container instance and volume.
Only the current working directory is mounted to /workspace in the container.
Dotfiles are automatically installed on first connect unless DEVC_DOTFILES_AUTO=false.
Secrets are automatically unpacked after dotfiles installation using secrets.sh if DEVC_SECRETS_AUTO=true (default).
For secrets to work, you need the 'secret' command available on the host and a secrets env file in DEVC_SECRETS_DIR.
The script sources the environment file (default: dotfiles.env, configurable via DEVC_SECRETS_ENV), then passes them to the container.
Enable debug output with DEVC_DEBUG=true to troubleshoot setup issues.

EOF
}

# Main command processing
main() {
    local command="${1:-help}"
    
    case "$command" in
        install|i)
            install_devcontainer
            ;;
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
            run_0jimbox
            ;;
        connect|c)
            check_docker
            connect_container
            ;;
        exec|e)
            check_docker
            shift  # Remove 'exec' from arguments
            exec_container "$@"
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
