#!/bin/bash

# Test script to verify Docker builds work correctly
# Tests Debian variant only

set -e

echo "=== Testing Docker Build Process ==="

# Function to handle build errors
handle_build_error() {
    local dockerfile="$1"
    local error_message="$2"
    echo "❌ Build failed for $dockerfile: $error_message"
    echo "Docker system info:"
    docker system info || true
    echo "Available disk space:"
    df -h || true
    exit 1
}

# Test 1: Build main Dockerfile (Debian-based)
echo "Testing Debian build..."
if ! docker build -t test-tinyproxy -f Dockerfile . 2>&1; then
    handle_build_error "Dockerfile" "Failed to build main image"
fi
echo "✅ Main build successful"

# Verify images were created
echo "Verifying built images..."
docker images | grep test-tinyproxy || {
    echo "❌ No test images found"
    exit 1
}

echo "=== Docker build completed successfully ==="