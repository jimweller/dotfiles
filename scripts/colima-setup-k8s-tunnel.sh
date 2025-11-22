#!/bin/bash
# Setup persistent SSH tunnel for kubectl access from Docker containers
# This creates a fixed port (6443) tunnel to the k3s API server
# Containers can access k8s via host.docker.internal:6443

set -e

# Configuration
TUNNEL_PORT=6443
COLIMA_SSH_CONFIG="$HOME/.colima/ssh_config"

# Check if Colima is running
if ! colima status &>/dev/null; then
    echo "Error: Colima is not running"
    exit 1
fi

# Get the k3s API port inside the VM
K3S_PORT=$(colima ssh -- "sudo ss -tlnp | grep k3s-server | grep 127.0.0.1 | awk '{print \$4}' | cut -d: -f2 | head -1")

if [ -z "$K3S_PORT" ]; then
    echo "Error: Could not detect k3s API port inside VM"
    exit 1
fi

echo "Detected k3s listening on port $K3S_PORT inside VM"

# Check if tunnel already exists
if lsof -nP -iTCP:$TUNNEL_PORT -sTCP:LISTEN &>/dev/null; then
    echo "SSH tunnel already exists on port $TUNNEL_PORT"
    exit 0
fi

# Create the SSH tunnel
echo "Creating SSH tunnel: localhost:$TUNNEL_PORT -> VM:$K3S_PORT"
ssh -f -N -L $TUNNEL_PORT:127.0.0.1:$K3S_PORT -F "$COLIMA_SSH_CONFIG" colima

# Verify tunnel was created
sleep 1
if lsof -nP -iTCP:$TUNNEL_PORT -sTCP:LISTEN &>/dev/null; then
    echo "✓ SSH tunnel created successfully"
    echo "✓ Containers can now access k8s via host.docker.internal:$TUNNEL_PORT"
else
    echo "Error: Failed to create SSH tunnel"
    exit 1
fi