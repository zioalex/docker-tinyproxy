# Docker Tinyproxy Test Suite

This directory contains a comprehensive test suite for the docker-tinyproxy project. The tests verify that Docker builds work correctly and that tinyproxy is functioning as expected.

## Test Scripts

### `test-docker-build.sh`
Tests the Docker build process for both Alpine and Debian variants:
- Builds the default Dockerfile (Alpine)
- Builds the Debian variant using Dockerfile.debian
- Verifies that all images build successfully

### `test-tinyproxy-service.sh`
Tests basic tinyproxy service functionality:
- Verifies that tinyproxy is listening on the expected port
- Tests custom port configuration
- Tests upstream proxy configuration
- Tests stats page functionality
- Tests both Alpine and Debian variants

### `test-upstream-proxy.sh`
Comprehensive tests for the upstream proxy feature:
- HTTP upstream proxy without domain filter
- HTTP upstream proxy with domain filter  
- SOCKS5 upstream proxy
- SOCKS4 upstream proxy with domain filter
- Authentication credential stripping
- Tests with both Alpine and Debian variants
- Baseline test without upstream proxy

## CI/CD Integration

### GitHub Actions
The test suite is integrated with GitHub Actions (`.github/workflows/test.yml`):
- Runs on push and pull requests
- Tests are executed in parallel for faster feedback
- Includes integration tests for docker-compose and healthchecks

### GitLab CI (Legacy)
The GitLab CI configuration (`.gitlab-ci.yml`) also includes test stages:
- Three parallel test jobs for build, service, and upstream proxy tests
- Tests run before the build and distribute stages

## Running Tests Locally

1. **Prerequisites:**
   - Docker installed and running
   - Bash shell
   - Execute permissions on test scripts

2. **Run all tests:**
   ```bash
   ./test-docker-build.sh
   ./test-tinyproxy-service.sh
   ./test-upstream-proxy.sh
   ```

3. **Run individual test suites:**
   ```bash
   # Test only Docker builds
   ./test-docker-build.sh
   
   # Test only service functionality
   ./test-docker-build.sh && ./test-tinyproxy-service.sh
   
   # Test only upstream proxy feature
   ./test-docker-build.sh && ./test-upstream-proxy.sh
   ```

## Test Coverage

The test suite covers:

✅ **Docker Build Process**
- Alpine variant build
- Debian variant build
- Multi-architecture support verification

✅ **Basic Service Functionality**
- Service startup and port binding
- Custom port configuration
- Stats page functionality
- Configuration file generation

✅ **Upstream Proxy Feature**
- HTTP upstream proxy support
- SOCKS4/SOCKS5 upstream proxy support
- Domain/network filtering
- Authentication credential handling
- Configuration syntax validation

✅ **Integration Testing**
- Docker Compose configuration validation
- Healthcheck functionality
- Container lifecycle management

## Test Output

Each test script provides clear output with:
- ✅ Success indicators for passed tests
- ❌ Failure indicators with detailed error information
- Automatic cleanup of test containers
- Logs from failed containers for debugging

## Troubleshooting

If tests fail:

1. **Check Docker daemon:** Ensure Docker is running and accessible
2. **Check disk space:** Docker builds require sufficient disk space
3. **Check network connectivity:** Some tests may require internet access for base image downloads
4. **Review logs:** Failed containers will have their logs displayed automatically
5. **Manual cleanup:** If needed, remove test containers manually:
   ```bash
   docker ps -a | grep test- | awk '{print $1}' | xargs docker rm -f
   ```

## Contributing

When adding new features:
1. Add corresponding tests to verify the functionality
2. Update this README if new test scripts are added
3. Ensure tests pass locally before submitting a pull request
4. Consider both Alpine and Debian variants in your tests