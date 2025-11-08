#!/bin/bash

# Script to fix file permissions for Docker containers
# This fixes ownership of files created by Docker containers
# Run from infra/ directory

echo "Fixing file permissions..."

cd "$(dirname "$0")"

# Get current user ID and group ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Using UID: $USER_ID, GID: $GROUP_ID"

# Fix frontend permissions
echo "Fixing frontend permissions..."
docker-compose exec -T frontend sh -c "chown -R ${USER_ID}:${GROUP_ID} /app" 2>/dev/null || echo "Frontend container not running"

# Fix backend permissions
echo "Fixing backend permissions..."
docker-compose exec -T backend sh -c "chown -R ${USER_ID}:${GROUP_ID} /var/www/html" 2>/dev/null || echo "Backend container not running"

echo "Done! New files created by containers will have correct permissions."

