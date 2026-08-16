# cswni/laravel — Docker Run Commands
# ─────────────────────────────────────────────────────────────────────────────
# Flags used in all commands:
#   -it     → interactive terminal (see logs, Ctrl+C to stop)
#   --rm    → container is automatically deleted when it exits
#   -v      → mount your Laravel app into the container
# ─────────────────────────────────────────────────────────────────────────────

# Web server — API mode (default)
docker run -it --rm --name laravel-api -p 8091:8080 -v "$(pwd)":/var/www/html -e APP_MODE=api -e APP_ENV=production cswni/laravel:0.0.1

# Horizon — queue worker
docker run -it --rm \
  --name laravel-horizon \
  -v "$(pwd)":/var/www/html \
  -e APP_MODE=horizon \
  -e APP_ENV=production \
  cswni/laravel:0.0.1

# Scheduler — task scheduler loop (runs every 60s)
docker run -it --rm \
  --name laravel-scheduler \
  -v "$(pwd)":/var/www/html \
  -e APP_MODE=scheduler \
  -e APP_ENV=production \
  cswni/laravel:0.0.1

# Reverb — WebSocket server
docker run -it --rm \
  --name laravel-reverb \
  -p 8080:8080 \
  -v "$(pwd)":/var/www/html \
  -e APP_MODE=reverb \
  -e APP_ENV=production \
  cswni/laravel:0.0.1

# ─────────────────────────────────────────────────────────────────────────────
# Open a bash shell inside an already-running container
docker exec -it laravel-api bash

# Enter the container directly (bypasses entrypoint — for debugging)
docker run -it --rm \
  --name laravel-shell \
  -v "$(pwd)":/var/www/html \
  -e APP_ENV=local \
  --entrypoint bash \
  cswni/laravel:0.0.1
# ─────────────────────────────────────────────────────────────────────────────

