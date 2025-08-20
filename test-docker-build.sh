#!/bin/bash

# Test script to verify Docker builds work correctly
# Tests both Alpine and Debian variants

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

# Test 1: Build Alpine variant (default Dockerfile)
echo "Testing Alpine build..."
if ! docker build -t test-tinyproxy-alpine -f Dockerfile . 2>&1; then
    handle_build_error "Dockerfile (Alpine)" "Failed to build default Alpine image"
fi
echo "✅ Alpine build successful"

# Test 2: Build Debian variant 
echo "Testing Debian build..."
if ! docker build -t test-tinyproxy-debian -f Dockerfile.debian . 2>&1; then
    handle_build_error "Dockerfile.debian" "Failed to build Debian image"
fi
echo "✅ Debian build successful"

# Test 3: Build Alpine variant using Dockerfile.alpine (if it exists and is different)
if [ -f "Dockerfile.alpine" ] && ! cmp -s "Dockerfile" "Dockerfile.alpine"; then
    echo "Testing Alpine build (explicit)..."
    if ! docker build -t test-tinyproxy-alpine-explicit -f Dockerfile.alpine . 2>&1; then
        handle_build_error "Dockerfile.alpine" "Failed to build explicit Alpine image"
    fi
    echo "✅ Alpine explicit build successful"
else
    echo "ℹ️  Dockerfile.alpine is same as Dockerfile, skipping duplicate build"
fi

# Verify images were created
echo "Verifying built images..."
docker images | grep test-tinyproxy || {
    echo "❌ No test images found"
    exit 1
}

echo "=== All Docker builds completed successfully ==="