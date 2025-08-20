#!/bin/bash

# Test script specifically for upstream proxy functionality
# Tests various upstream proxy configurations

set -e

echo "=== Testing Upstream Proxy Feature ==="

# Check which test image is available
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "test-tinyproxy-alpine"; then
    TEST_IMAGE="test-tinyproxy-alpine"
    echo "Using Alpine image for upstream proxy tests"
elif docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "test-tinyproxy-debian"; then
    TEST_IMAGE="test-tinyproxy-debian"
    echo "Using Debian image for upstream proxy tests"
else
    echo "❌ No test images available"
    exit 1
fi

# Cleanup function
cleanup_container() {
    local container_name="$1"
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Cleaning up container: $container_name"
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    fi
}

# Test helper function to check configuration
check_upstream_config() {
    local container_name="$1"
    local expected_config="$2"
    
    echo "Checking upstream configuration in $container_name..."
    local config_content=$(docker exec "$container_name" cat /etc/tinyproxy/tinyproxy.conf)
    
    if echo "$config_content" | grep -F "$expected_config" > /dev/null; then
        echo "✅ Found expected config: $expected_config"
        return 0
    else
        echo "❌ Expected config not found: $expected_config"
        echo "Actual config content:"
        echo "$config_content" | grep -E "^(Upstream|#.*Upstream)" || echo "No Upstream lines found"
        return 1
    fi
}

# Test 1: HTTP upstream proxy without domain
echo "Testing HTTP upstream proxy without domain..."
cleanup_container test-upstream-http
docker run -d --name test-upstream-http \
    -e UPSTREAM_PROXY="http://proxy.example.com:8080" \
    $TEST_IMAGE
sleep 3
check_upstream_config test-upstream-http "Upstream http proxy.example.com:8080"
cleanup_container test-upstream-http
echo "✅ HTTP upstream proxy test passed"

# Test 2: HTTP upstream proxy with domain filter
echo "Testing HTTP upstream proxy with domain filter..."
cleanup_container test-upstream-http-domain
docker run -d --name test-upstream-http-domain \
    -e UPSTREAM_PROXY="http://proxy.example.com:8080" \
    -e UPSTREAM_DOMAIN=".corporate.com" \
    $TEST_IMAGE
sleep 3
check_upstream_config test-upstream-http-domain "Upstream http proxy.example.com:8080 \".corporate.com\""
cleanup_container test-upstream-http-domain
echo "✅ HTTP upstream proxy with domain test passed"

# Test 3: SOCKS5 upstream proxy
echo "Testing SOCKS5 upstream proxy..."
cleanup_container test-upstream-socks5
docker run -d --name test-upstream-socks5 \
    -e UPSTREAM_PROXY="socks5://socks.example.com:1080" \
    $TEST_IMAGE
sleep 3
check_upstream_config test-upstream-socks5 "Upstream socks5 socks.example.com:1080"
cleanup_container test-upstream-socks5
echo "✅ SOCKS5 upstream proxy test passed"

# Test 4: SOCKS4 upstream proxy with domain filter
echo "Testing SOCKS4 upstream proxy with domain filter..."
cleanup_container test-upstream-socks4
docker run -d --name test-upstream-socks4 \
    -e UPSTREAM_PROXY="socks4://socks.example.com:1080" \
    -e UPSTREAM_DOMAIN="10.0.0.0/8" \
    $TEST_IMAGE
sleep 3
check_upstream_config test-upstream-socks4 "Upstream socks4 socks.example.com:1080 \"10.0.0.0/8\""
cleanup_container test-upstream-socks4
echo "✅ SOCKS4 upstream proxy with domain test passed"

# Test 5: Upstream proxy with authentication (should strip auth)
echo "Testing upstream proxy with authentication credentials..."
cleanup_container test-upstream-auth
docker run -d --name test-upstream-auth \
    -e UPSTREAM_PROXY="http://user:pass@proxy.example.com:8080" \
    $TEST_IMAGE
sleep 3
# Should strip authentication and use only host:port
check_upstream_config test-upstream-auth "Upstream http proxy.example.com:8080"
cleanup_container test-upstream-auth
echo "✅ Upstream proxy with authentication test passed"

# Test 6: Test with different variant (if both available)
if [ "$TEST_IMAGE" = "test-tinyproxy-alpine" ] && docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "test-tinyproxy-debian"; then
    echo "Testing upstream proxy with Debian variant..."
    cleanup_container test-upstream-debian
    docker run -d --name test-upstream-debian \
        -e UPSTREAM_PROXY="http://proxy.example.com:3128" \
        -e UPSTREAM_DOMAIN=".intranet.com" \
        test-tinyproxy-debian
    sleep 3
    check_upstream_config test-upstream-debian "Upstream http proxy.example.com:3128 \".intranet.com\""
    cleanup_container test-upstream-debian
    echo "✅ Debian upstream proxy test passed"
elif [ "$TEST_IMAGE" = "test-tinyproxy-debian" ]; then
    echo "ℹ️  Only Debian image available, skipping Alpine variant test"
fi

# Test 7: No upstream proxy (baseline test)
echo "Testing container without upstream proxy..."
cleanup_container test-no-upstream
docker run -d --name test-no-upstream $TEST_IMAGE
sleep 3
config_content=$(docker exec test-no-upstream cat /etc/tinyproxy/tinyproxy.conf)
if echo "$config_content" | grep "^Upstream" > /dev/null; then
    echo "❌ Found unexpected Upstream configuration"
    echo "$config_content" | grep "^Upstream"
    cleanup_container test-no-upstream
    exit 1
else
    echo "✅ No upstream configuration found (as expected)"
fi
cleanup_container test-no-upstream
echo "✅ No upstream proxy test passed"

echo "=== All upstream proxy tests completed successfully ==="