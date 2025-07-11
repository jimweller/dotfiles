#!/bin/bash

# DevContainer management script
# Usage: devcontainer.sh [build|run|connect]

# Function to run the devcontainer
run_devcontainer() {
    docker run -d \
      --name devcontainer \
      --restart unless-stopped \
      --mount source=devcontainer-homedir,target=/home/vscode \
      --mount type=bind,source=/Users/jimweller/Projects/work,target=/home/vscode/Projects/work \
      --mount type=bind,source=/Users/jimweller/Projects/personal,target=/home/vscode/Projects/personal \
      --user $(id -u):$(id -g) \
      devcontainer \
      sleep infinity
}

MODE="${1:-help}"

case "$MODE" in
    build)
        docker stop devcontainer 2>/dev/null || true
        docker rm devcontainer 2>/dev/null || true
        HOST_UID=$(id -u)
        HOST_GID=$(id -g)
        docker build \
          --build-arg USER_UID=$HOST_UID \
          --build-arg USER_GID=$HOST_GID \
          --progress=plain \
          -t devcontainer ~/.dotfiles/devcontainer
        run_devcontainer
        ;;
    run)
        run_devcontainer
        ;;
    connect)
        docker exec -it devcontainer /bin/zsh
        ;;
    help|*)
        echo "Usage: devcontainer.sh [build|run|connect]"
        echo ""
        echo "Commands:"
        echo "  build   - Build the devcontainer"
        echo "  run     - Run the devcontainer"
        echo "  connect - Connect to the running devcontainer"
        exit 1
        ;;
esac
