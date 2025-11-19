#!/bin/bash

# PostgreSQL Docker Container Management Script
# This script starts a PostgreSQL 17 container with persistent data storage

CONTAINER_NAME="postgres17"
IMAGE="postgres:17"
PASSWORD="99bottles"
PORT="5432"
DATA_DIR="$HOME/assets/postgres/data"
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
fi

# Start the PostgreSQL container
echo "Starting PostgreSQL container: ${CONTAINER_NAME}"
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart always \
    --user "${USER_ID}:${GROUP_ID}" \
    -e POSTGRES_PASSWORD="${PASSWORD}" \
    -p "${PORT}:5432" \
    -v "${DATA_DIR}:/var/lib/postgresql/data" \
    "${IMAGE}"

# Check if container started successfully
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✓ PostgreSQL container started successfully"
    echo "  Container: ${CONTAINER_NAME}"
    echo "  Port: ${PORT}"
    echo "  Data: ${DATA_DIR}"
else
    echo "✗ Failed to start PostgreSQL container"
    exit 1
fi
