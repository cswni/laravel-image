# 🚀 Complete New PHP 8.5 FrankenPHP Implementation

## ✅ What's Included

All files are in the `php-image-8-5/` directory:

### Core Files
- ✅ **Dockerfile** - Optimized, clean, production-ready
- ✅ **Caddyfile** - Simple configuration, no worker mode
- ✅ **docker-compose.yml** - Full stack with MySQL & Redis
- ✅ **.env.example** - All environment variables documented

### Configuration
- ✅ **docker/php/php.ini** - PHP settings with env var support
- ✅ **docker/php/opcache.ini** - OPcache configuration
- ✅ **docker/entrypoints/entrypoint.sh** - Smart entrypoint with auto-optimization

### Testing & Utilities
- ✅ **docker/entrypoints/test.sh** - General PHP/extension tests
- ✅ **docker/entrypoints/test-curl.sh** - Comprehensive curl tests
- ✅ **build.sh** - Easy build script with registry support

### Documentation
- ✅ **README.md** - Complete usage guide
- ✅ **COMMANDS.md** - All commands reference
- ✅ **IMPLEMENTATION-NOTES.md** - Technical details & fixes
- ✅ **QUICK-START.md** - This file

---

## 🎯 Key Features

### 1. Curl Extension Fixed
- ✅ Uses curl from base image (already present)
- ✅ Explicit curl.cainfo certificate configuration
- ✅ Comprehensive curl testing included
- ✅ Works with Spatie Ray and any curl usage

### 2. No Worker Mode
- ✅ Standard PHP/Laravel execution
- ✅ Simple Caddyfile without complex worker configuration
- ✅ No "file argument must be specified" errors

### 3. Environment-Based Configuration
- ✅ Same image works for development AND production
- ✅ All PHP settings controllable via environment variables
- ✅ Auto-optimization in production mode
- ✅ Auto-cache clearing in development mode

### 4. All Extensions Included
```
✅ curl (built-in)      ✅ opcache
✅ gd (webp support)    ✅ sockets
✅ pdo_mysql            ✅ redis
✅ pdo_pgsql            ✅ imagick
✅ zip                  ✅ intl
✅ pcntl                ✅ exif
✅ bcmath
```

### 5. Production Optimizations
- ✅ Multi-core compilation (-j$(nproc))
- ✅ Minimal layers
- ✅ Cleaned up artifacts
- ✅ OPcache file cache enabled
- ✅ Proper permissions

---

## 🚀 Quick Start

### Step 1: Navigate to Directory
```bash
cd php-image-8-5
```

### Step 2: Build the Image
```bash
docker build -t laravel-app:latest .
```

### Step 3: Test Extensions (Optional but Recommended)
```bash
# Quick test
docker run --rm laravel-app:latest php -m | grep curl

# Comprehensive test
docker run --rm laravel-app:latest bash /usr/local/bin/test-curl
```

### Step 4: Configure Environment
```bash
# Copy example to parent directory
cp .env.example ../.env

# Edit with your settings
nano ../.env
```

Minimum required:
```env
APP_ENV=production
APP_KEY=base64:your-key-here
APP_DEBUG=false
DB_HOST=mysql
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### Step 5: Run with Docker Compose
```bash
docker-compose up -d
```

Or run standalone:
```bash
docker run -d \
  --name laravel-app \
  -p 8080:8080 \
  -v $(pwd)/../:/var/www/html \
  --env-file ../.env \
  laravel-app:latest
```

### Step 6: Verify
```bash
# Check logs
docker logs -f laravel-app

# Access your app
curl http://localhost:8080

# Run Laravel commands
docker exec laravel-app php artisan migrate
```

---

## 🔧 For Remote Linux Server

### Build on Server
```bash
# Upload php-image-8-5 directory to server
scp -r php-image-8-5 user@server:/path/to/

# SSH to server
ssh user@server

# Navigate and build
cd /path/to/php-image-8-5
docker build -t laravel-app:latest .

# Test curl specifically
docker run --rm laravel-app:latest bash /usr/local/bin/test-curl
```

### Deploy
```bash
# Make sure .env is configured
cp .env.example /path/to/laravel/.env
nano /path/to/laravel/.env

# Run container
docker run -d \
  --name laravel-app \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /path/to/laravel:/var/www/html \
  --env-file /path/to/laravel/.env \
  laravel-app:latest

# Monitor logs
docker logs -f laravel-app
```

---

## 🐛 Troubleshooting

### If You Still Get curl_exec() Errors

1. **Check if curl is loaded:**
```bash
docker exec laravel-app php -m | grep curl
```

2. **Run comprehensive curl test:**
```bash
docker exec laravel-app bash /usr/local/bin/test-curl
```

3. **Check Spatie Ray configuration:**
```bash
# In your Laravel app, check if Ray is enabled in production
# You might want to disable it or configure it properly
```

4. **Test curl directly in PHP:**
```bash
docker exec laravel-app php -r "var_dump(function_exists('curl_exec'));"
```

### Common Issues

**Problem:** Permission denied on storage
```bash
docker exec laravel-app chown -R www-data:www-data /var/www/html/storage
docker exec laravel-app chmod -R 775 /var/www/html/storage
```

**Problem:** OPcache not clearing
```bash
docker exec laravel-app php artisan optimize:clear
docker restart laravel-app
```

**Problem:** Database connection refused
```bash
# Check if MySQL container is running
docker ps | grep mysql

# Check DB_HOST in .env matches container name
```

---

## 📊 Environment Variables Reference

### Application
- `APP_ENV` - production/local/development
- `APP_DEBUG` - true/false
- `APP_KEY` - Laravel encryption key

### PHP Settings
- `PHP_MEMORY_LIMIT` (default: 512M)
- `PHP_MAX_EXECUTION_TIME` (default: 60)
- `PHP_POST_MAX_SIZE` (default: 100M)
- `PHP_UPLOAD_MAX_FILESIZE` (default: 100M)
- `PHP_TIMEZONE` (default: UTC)

### OPcache
- `PHP_OPCACHE_ENABLE` (default: 1)
- `PHP_OPCACHE_VALIDATE_TIMESTAMPS` (0 for prod, 1 for dev)

### Database
- `DB_CONNECTION`, `DB_HOST`, `DB_PORT`
- `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`

### Cache/Queue
- `CACHE_DRIVER`, `QUEUE_CONNECTION`, `SESSION_DRIVER`
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`

---

## 📚 Additional Resources

- **README.md** - Full documentation
- **COMMANDS.md** - All Docker/PHP commands
- **IMPLEMENTATION-NOTES.md** - Technical details about fixes
- **docker-compose.yml** - Full stack setup example

---

## ✨ What Makes This Different

### Compared to Previous Implementation:

| Feature | Old | New |
|---------|-----|-----|
| Curl Config | Missing/Incorrect | Explicit with certs |
| Caddyfile | Worker mode | Standard mode |
| Environment | Build-time | Runtime |
| Testing | None | Comprehensive |
| Documentation | Scattered | Complete |
| Entrypoint | Multiple complex | Single unified |

### Why It Should Work:

1. ✅ **curl is confirmed in base image** - We don't try to install it
2. ✅ **Proper SSL cert configuration** - curl.cainfo explicitly set
3. ✅ **No worker mode** - Simple, standard FrankenPHP
4. ✅ **Environment variables** - Easy to configure per environment
5. ✅ **Test scripts included** - Easy to verify everything
6. ✅ **Follows Laravel best practices** - Standard directory structure

---

## 🎉 Success Criteria

After deployment, you should see:

```
🚀 Laravel FrankenPHP Container Starting
   Environment: production
   Debug: false
📦 Production mode
⚡ Running optimizations
✅ Optimizations complete

📊 PHP Configuration:
   Memory: 512M
   Max Execution: 60s
   OPcache: 1
   OPcache Validation: 0

📦 PHP Extensions:
curl
gd
pdo_mysql
redis
opcache
...

INF | FrankenPHP started 🐘
```

**NO curl_exec() errors!** 🎊

---

## 💡 Tips

1. **Always test curl after building:**
   ```bash
   docker run --rm laravel-app:latest bash /usr/local/bin/test-curl
   ```

2. **Use docker-compose for local development** - includes MySQL & Redis

3. **Set PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 in development** for instant code changes

4. **Monitor logs during first startup** to catch any issues early

5. **Keep .env file secure** - never commit it to git

---

## 🆘 Need Help?

If issues persist:

1. Run the curl test script and share output
2. Check FrankenPHP logs
3. Verify .env configuration
4. Test with minimal Laravel installation first
5. Check if Spatie Ray is configured correctly for your environment

---

**Built with ❤️ for Laravel + FrankenPHP + PHP 8.5**

