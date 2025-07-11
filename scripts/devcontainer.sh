#!/bin/bash

# DevContainer management script
# Usage: devcontainer.sh [build|b|run|r|connect|c]

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
    build|b)
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
    run|r)
        run_devcontainer
        ;;
    connect|c)
        docker exec -it devcontainer /bin/zsh
        ;;
    help|*)
        echo "Usage: devcontainer.sh [build|b|run|r|connect|c]"
        echo ""
        echo "Commands:"
        echo "  build (b)   - Build the devcontainer"
        echo "  run (r)     - Run the devcontainer"
        echo "  connect (c) - Connect to the running devcontainer"
        exit 1
        ;;
esac
