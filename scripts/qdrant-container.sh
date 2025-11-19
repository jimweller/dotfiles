#!/bin/bash

# Qdrant Docker Container Management Script
# This script starts a Qdrant vector database container with persistent data storage

CONTAINER_NAME="qdrant"
IMAGE="qdrant/qdrant"
PORT="6333"
DATA_DIR="$HOME/assets/qdrant/data"

# Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
fi

# Start the Qdrant container
echo "Starting Qdrant container: ${CONTAINER_NAME}"
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${PORT}:6333" \
    -v "${DATA_DIR}:/qdrant/storage" \
    "${IMAGE}"

# Check if container started successfully
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✓ Qdrant container started successfully"
    echo "  Container: ${CONTAINER_NAME}"
    echo "  Port: ${PORT}"
    echo "  Data: ${DATA_DIR}"
else
    echo "✗ Failed to start Qdrant container"
    exit 1
fi