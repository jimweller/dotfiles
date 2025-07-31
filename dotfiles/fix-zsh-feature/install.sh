#!/bin/sh
# This script runs as root during the container build.
# The default non-root user in dev containers is 'vscode' with home dir /home/vscode.
touch /home/vscode/.zshrc