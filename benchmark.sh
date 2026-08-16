#!/bin/bash

# Laravel FrankenPHP Performance Benchmark Script
# This script runs various performance tests on your Laravel application

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOST="${BENCHMARK_HOST:-http://localhost:8080}"
REQUESTS="${BENCHMARK_REQUESTS:-10000}"
CONCURRENCY="${BENCHMARK_CONCURRENCY:-100}"

echo -e "${BLUE}🚀 Laravel FrankenPHP Performance Benchmark${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "Host:        ${GREEN}${HOST}${NC}"
echo -e "Requests:    ${GREEN}${REQUESTS}${NC}"
echo -e "Concurrency: ${GREEN}${CONCURRENCY}${NC}"
echo ""

# Check if ab (Apache Bench) is available
if ! command -v ab &> /dev/null; then
    echo -e "${RED}❌ Apache Bench (ab) not found!${NC}"
    echo -e "${YELLOW}Install it with: apt-get install apache2-utils${NC}"
    exit 1
fi

# Function to run benchmark
run_benchmark() {
    local endpoint=$1
    local description=$2

    echo -e "${YELLOW}📊 Testing: ${description}${NC}"
    echo -e "   Endpoint: ${endpoint}"

    ab -n "${REQUESTS}" -c "${CONCURRENCY}" -q "${HOST}${endpoint}" > /tmp/benchmark_result.txt 2>&1

    # Extract key metrics
    local rps=$(grep "Requests per second" /tmp/benchmark_result.txt | awk '{print $4}')
    local time_per_request=$(grep "Time per request" /tmp/benchmark_result.txt | head -1 | awk '{print $4}')
    local failed=$(grep "Failed requests" /tmp/benchmark_result.txt | awk '{print $3}')

    echo -e "   ${GREEN}✓${NC} Requests/sec:      ${GREEN}${rps}${NC}"
    echo -e "   ${GREEN}✓${NC} Time/request:      ${GREEN}${time_per_request} ms${NC}"
    echo -e "   ${GREEN}✓${NC} Failed requests:   ${GREEN}${failed}${NC}"
    echo ""
}

# Check if server is running
echo -e "${BLUE}🔍 Checking server status...${NC}"
if ! curl -s -f "${HOST}" > /dev/null; then
    echo -e "${RED}❌ Server is not responding at ${HOST}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Server is running${NC}"
echo ""

# Get PHP and OPcache info
echo -e "${BLUE}📋 Server Configuration${NC}"
echo -e "${YELLOW}─────────────────────────${NC}"
docker exec laravel-app php -v | head -1
docker exec laravel-app php -r "
echo 'OPcache Enabled:    ' . (ini_get('opcache.enable') ? 'YES' : 'NO') . PHP_EOL;
echo 'Validate Timestamp: ' . (ini_get('opcache.validate_timestamps') ? 'YES' : 'NO') . PHP_EOL;
echo 'JIT Mode:           ' . ini_get('opcache.jit') . PHP_EOL;
echo 'Memory Limit:       ' . ini_get('memory_limit') . PHP_EOL;
"
echo ""

# Warm up
echo -e "${YELLOW}🔥 Warming up (1000 requests)...${NC}"
ab -n 1000 -c 10 -q "${HOST}/" > /dev/null 2>&1
echo -e "${GREEN}✓ Warm up complete${NC}"
echo ""

# Run benchmarks
echo -e "${BLUE}📊 Running Benchmarks${NC}"
echo -e "${YELLOW}════════════════════${NC}"
echo ""

# Homepage
run_benchmark "/" "Homepage"

# API Health Check (if available)
if curl -s -f "${HOST}/api/health" > /dev/null 2>&1; then
    run_benchmark "/api/health" "API Health Check"
fi

# Summary
echo -e "${BLUE}📈 Benchmark Summary${NC}"
echo -e "${YELLOW}═══════════════════${NC}"
cat /tmp/benchmark_result.txt | grep -E "(Requests per second|Time per request|Transfer rate|Percentage of the requests)"
echo ""

echo -e "${GREEN}✅ Benchmark complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Tips for better performance:${NC}"
echo -e "   • Enable OPcache preload for 10-20% boost"
echo -e "   • Use FrankenPHP worker mode for 5-10x improvement"
echo -e "   • Set PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 in production"
echo -e "   • Increase FRANKENPHP_NUM_THREADS based on CPU cores"
echo ""

# Cleanup
rm -f /tmp/benchmark_result.txt

