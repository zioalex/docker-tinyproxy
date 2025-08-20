#!/bin/bash

# Test script to verify tinyproxy service functionality
# Tests basic proxy functionality and upstream proxy feature

set -e

echo "=== Testing Tinyproxy Service Functionality ==="

# Cleanup function
cleanup_container() {
    local container_name="$1"
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Cleaning up container: $container_name"
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    fi
}

# Test helper function to wait for service to be ready
wait_for_service() {
    local container_name="$1"
    local port="$2"
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for $container_name to be ready on port $port..."
    while [ $attempt -lt $max_attempts ]; do
        # Try multiple methods to check if port is listening
        if docker exec "$container_name" which ss >/dev/null 2>&1; then
            if docker exec "$container_name" ss -ln 2>/dev/null | grep ":$port " > /dev/null; then
                echo "✅ $container_name is ready on port $port"
                return 0
            fi
        elif docker exec "$container_name" which netstat >/dev/null 2>&1; then
            if docker exec "$container_name" netstat -ln 2>/dev/null | grep ":$port " > /dev/null; then
                echo "✅ $container_name is ready on port $port"
                return 0
            fi
        else
            # Fallback: check if process is listening
            if docker exec "$container_name" sh -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
                echo "✅ $container_name is ready on port $port"
                return 0
            fi
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    echo "❌ $container_name failed to start after $max_attempts attempts"
    docker logs "$container_name" || true
    return 1
}

# Test helper function to check if tinyproxy is listening
check_tinyproxy_listening() {
    local container_name="$1"
    local port="$2"
    
    echo "Checking if tinyproxy is listening on port $port in $container_name..."
    
    # Simple approach: try to make a connection to the proxy
    if docker exec "$container_name" curl -x "localhost:$port" -I -s --connect-timeout 3 "http://httpbin.org/get" >/dev/null 2>&1; then
        echo "✅ Tinyproxy is listening and responding on port $port"
        return 0
    fi
    
    # Fallback: check if we can connect to the port directly
    if docker exec "$container_name" sh -c "timeout 3 sh -c '</dev/tcp/localhost/$port'" 2>/dev/null; then
        echo "✅ Port $port is accessible"
        return 0
    fi
    
    echo "❌ Tinyproxy is not listening or not responding on port $port"
    echo "Container logs:"
    docker logs "$container_name" | tail -10
    return 1
}

# Determine which test image to use
TEST_IMAGE="test-tinyproxy"

# Test 1: Basic container functionality
echo "Testing basic container functionality..."
cleanup_container test-basic
docker run -d --name test-basic -p 18888:8888 $TEST_IMAGE
sleep 5
check_tinyproxy_listening test-basic 8888
cleanup_container test-basic
echo "✅ Basic container test passed"

# Test 2: Custom port configuration
echo "Testing custom port configuration..."
cleanup_container test-custom-port
docker run -d --name test-custom-port -p 19999:9999 -e PORT=9999 $TEST_IMAGE
sleep 5
check_tinyproxy_listening test-custom-port 9999
cleanup_container test-custom-port
echo "✅ Custom port configuration test passed"

# Test 3: Upstream proxy configuration
echo "Testing upstream proxy configuration..."
cleanup_container test-upstream
docker run -d --name test-upstream \
    -e UPSTREAM_PROXY="http://proxy.example.com:8080" \
    -e UPSTREAM_DOMAIN=".example.com" \
    $TEST_IMAGE
sleep 5
check_tinyproxy_listening test-upstream 8888

# Verify upstream configuration was applied
echo "Checking upstream proxy configuration..."
docker exec test-upstream cat /etc/tinyproxy/tinyproxy.conf | grep "Upstream" || {
    echo "❌ Upstream configuration not found"
    docker logs test-upstream
    cleanup_container test-upstream
    exit 1
}
echo "✅ Upstream proxy configuration found"

cleanup_container test-upstream
echo "✅ Upstream proxy configuration test passed"

# Test 4: Stats page functionality
echo "Testing stats page functionality..."
cleanup_container test-stats
docker run -d --name test-stats \
    -e STAT_HOST="tinyproxy.stats" \
    $TEST_IMAGE
sleep 5
check_tinyproxy_listening test-stats 8888

# Try to access stats page
echo "Checking stats page..."
if docker exec test-stats curl -f -s -H "Host: tinyproxy.stats" "http://localhost:8888" | grep -i "tinyproxy" > /dev/null; then
    echo "✅ Stats page is accessible"
else
    echo "❌ Stats page is not accessible"
    docker logs test-stats
    cleanup_container test-stats
    exit 1
fi

cleanup_container test-stats
echo "✅ Stats page functionality test passed"

echo "=== All Tinyproxy service tests completed successfully ==="