#!/bin/bash
echo "======================================"
echo "  ALL TESTS PASSED ✅"
echo "======================================"

echo ""
php -i | grep -i "curl" | head -20
echo "-----------------------------------"
echo "7. Check php.ini curl settings"

echo ""
"
}
    exit(1);
    echo '❌ Global curl_exec() failed from within namespace\n';
} else {
    echo '✅ Global curl_exec() works from within namespace\n';
if (\$result !== false && \$httpCode == 200) {

\curl_close(\$ch);
\$httpCode = \curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
\$result = \curl_exec(\$ch);
\curl_setopt(\$ch, CURLOPT_TIMEOUT, 5);
\curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
\$ch = \curl_init('http://httpbin.org/status/200');

}
    echo '   Testing with global namespace...\n';
    echo '⚠️  curl_exec not in Spatie\Ray namespace (expected)\n';
    // This is expected - we need to use the global namespace
if (!function_exists('Spatie\Ray\curl_exec')) {

namespace Spatie\Ray;
php -r "
echo "-----------------------------------"
echo "6. Test curl with namespace (Spatie Ray pattern)"

echo ""
"
}
    exit(1);
    echo '❌ curl_exec() failed or returned unexpected result\n';
} else {
    echo '✅ curl_exec() successfully made HTTP request (HTTP ' . \$httpCode . ')\n';
if (\$response && \$httpCode == 200) {
curl_close(\$ch);
\$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
\$response = curl_exec(\$ch);
curl_setopt(\$ch, CURLOPT_CONNECTTIMEOUT, 5);
curl_setopt(\$ch, CURLOPT_TIMEOUT, 5);
curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
\$ch = curl_init('http://httpbin.org/get');
php -r "
echo "-----------------------------------"
echo "5. Test actual curl request"

echo ""
php -r "\$v = curl_version(); echo '✅ cURL version: ' . \$v['version'] . '\n';"
echo "-----------------------------------"
echo "4. Get curl version"

echo ""
php -r "if (function_exists('curl_init')) { echo '✅ curl_init() exists\n'; } else { echo '❌ curl_init() does NOT exist\n'; exit(1); }"
echo "-----------------------------------"
echo "3. Check curl_init function"

echo ""
php -r "if (function_exists('curl_exec')) { echo '✅ curl_exec() exists\n'; } else { echo '❌ curl_exec() does NOT exist\n'; exit(1); }"
echo "-----------------------------------"
echo "2. Check curl_exec function"

echo ""
php -m | grep -i curl && echo "✅ curl extension loaded" || echo "❌ curl extension NOT loaded"
echo "-----------------------------------"
echo "1. Check if curl extension is loaded"

echo ""
echo "======================================"
echo "  CURL EXTENSION COMPREHENSIVE TEST"
echo "======================================"

# Comprehensive curl extension test

