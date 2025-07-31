#!/bin/sh
# This script runs as root during the container build.
# The default non-root user in dev containers is 'vscode' with home dir /home/vscode.
cat > /home/vscode/.zshrc << 'EOF'
# Wait for dotfiles to complete
if [[ ! -L ~/.zshrc ]]; then
  echo "⏳ Waiting for dotfiles installation..."
  while [[ ! -L ~/.zshrc ]]; do sleep 1; done
  exec zsh
fi
# This will never execute - the real .zshrc takes over via symlink
EOF