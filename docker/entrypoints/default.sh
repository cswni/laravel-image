#!/bin/sh
set -e

# ─── ANSI Colors ──────────────────────────────────────────────────────────────
R='\033[0m'
B='\033[1m'
DIM='\033[2m'
GRN='\033[1;32m'
YLW='\033[1;33m'
CYN='\033[1;36m'
WHT='\033[1;37m'
MGT='\033[1;35m'

# ─── Collect runtime info ─────────────────────────────────────────────────────
PHP_VER=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
NODE_VER=$(node --version 2>/dev/null || echo "not installed")
MODE="${APP_MODE:-api}"
ENV="${APP_ENV:-local}"

# ─── ASCII Banner ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYN}${B}  ██╗      █████╗ ██████╗  █████╗ ██╗   ██╗███████╗██╗     ${R}"
echo -e "${CYN}${B}  ██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔════╝██║     ${R}"
echo -e "${CYN}${B}  ██║     ███████║██████╔╝███████║██║   ██║█████╗  ██║     ${R}"
echo -e "${CYN}${B}  ██║     ██╔══██║██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║     ${R}"
echo -e "${CYN}${B}  ███████╗██║  ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗███████╗${R}"
echo -e "${CYN}${B}  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝${R}"
echo ""
echo -e "  ${DIM}⚡ FrankenPHP · PHP 8.4 · Caddy · Node.js 22${R}"
echo ""

# ─── Runtime info ─────────────────────────────────────────────────────────────
echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo -e "  ${WHT}${B}  Runtime${R}"
echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo -e "    🐘  PHP        ${GRN}${B}${PHP_VER}${R}"
echo -e "    📦  Node.js    ${GRN}${B}${NODE_VER}${R}"
echo -e "    🎯  Mode       ${YLW}${B}${MODE}${R}"
echo -e "    🌍  Env        ${YLW}${B}${ENV}${R}"
echo ""

# ─── Available modes ──────────────────────────────────────────────────────────
echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo -e "  ${WHT}${B}  Available Modes  ${DIM}(set APP_MODE= in your docker-compose)${R}"
echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo -e "    ${CYN}api${R}         FrankenPHP web server ${DIM}(traditional in local/dev · Octane in production)${R}"
echo -e "    ${CYN}horizon${R}     Laravel Horizon queue supervisor"
echo -e "    ${CYN}reverb${R}      Laravel Reverb WebSocket server"
echo -e "    ${CYN}scheduler${R}   Laravel task scheduler loop"
echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo ""

# ─── Dispatch to mode entrypoint ──────────────────────────────────────────────
echo -e "  🔧 ${B}Launching mode:${R} ${YLW}${B}${MODE}${R}"

CUSTOM_ENTRYPOINT="/usr/local/bin/${MODE}.sh"

if [ -f "$CUSTOM_ENTRYPOINT" ]; then
  echo -e "  🚀 ${GRN}${B}Starting:${R} ${CUSTOM_ENTRYPOINT}"
  echo ""
  exec sh "$CUSTOM_ENTRYPOINT"
else
  echo -e "  ${YLW}⚠️  No entrypoint found for mode '${MODE}'. Falling back to API mode.${R}"
  echo ""
  exec frankenphp run --config=/etc/caddy/Caddyfile
fi
