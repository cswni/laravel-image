# Laravel FrankenPHP Management Script for Windows
# Usage: .\manage.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# Colors
$Blue = "Cyan"
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Show-Help {
    Write-ColorOutput $Blue "🚀 Laravel FrankenPHP Management Script"
    Write-Output ""
    Write-Output "Available Commands:"
    Write-Output ""
    Write-Output "  Build & Deploy:"
    Write-Output "    build         Build the optimized Docker image"
    Write-Output "    build-prod    Build for production"
    Write-Output "    build-dev     Build for development"
    Write-Output ""
    Write-Output "  Container Management:"
    Write-Output "    up            Start all containers"
    Write-Output "    up-prod       Start in production mode"
    Write-Output "    up-dev        Start in development mode"
    Write-Output "    down          Stop all containers"
    Write-Output "    restart       Restart all containers"
    Write-Output "    logs          Show container logs"
    Write-Output ""
    Write-Output "  Laravel Commands:"
    Write-Output "    shell         Open shell in app container"
    Write-Output "    optimize      Run Laravel optimizations"
    Write-Output "    clear-cache   Clear all Laravel caches"
    Write-Output "    migrate       Run database migrations"
    Write-Output "    test          Run PHPUnit tests"
    Write-Output ""
    Write-Output "  Monitoring:"
    Write-Output "    check-opcache Check OPcache status"
    Write-Output "    check-php     Show PHP configuration"
    Write-Output "    health        Check container health"
    Write-Output ""
    Write-Output "  Utilities:"
    Write-Output "    install       Complete installation"
    Write-Output "    clean         Remove all containers and volumes"
    Write-Output ""
    Write-Output "Example: .\manage.ps1 up-dev"
    Write-Output ""
}

function Build-Image {
    Write-ColorOutput $Blue "🔨 Building optimized Docker image..."
    docker build -f Dockerfile.optimized -t laravel-frankenphp:latest .
}

function Build-Prod {
    Write-ColorOutput $Blue "🔨 Building production image..."
    docker build -f Dockerfile.optimized -t laravel-frankenphp:production .
}

function Build-Dev {
    Write-ColorOutput $Blue "🔨 Building development image..."
    docker build -f Dockerfile.optimized -t laravel-frankenphp:development .
}

function Start-Containers {
    Write-ColorOutput $Blue "🚀 Starting containers..."
    docker-compose -f docker-compose.optimized.yml up -d
}

function Start-Production {
    Write-ColorOutput $Blue "🚀 Starting in PRODUCTION mode..."
    if (Test-Path .env.production.example) {
        Copy-Item .env.production.example .env -Force
    }
    docker-compose -f docker-compose.optimized.yml up -d --build
}

function Start-Development {
    Write-ColorOutput $Blue "🚀 Starting in DEVELOPMENT mode..."
    if (Test-Path .env.development.example) {
        Copy-Item .env.development.example .env -Force
    }
    docker-compose -f docker-compose.optimized.yml up -d --build
}

function Stop-Containers {
    Write-ColorOutput $Yellow "⏹️ Stopping containers..."
    docker-compose -f docker-compose.optimized.yml down
}

function Restart-Containers {
    Write-ColorOutput $Yellow "🔄 Restarting containers..."
    docker-compose -f docker-compose.optimized.yml restart
}

function Show-Logs {
    Write-ColorOutput $Blue "📋 Showing container logs..."
    docker-compose -f docker-compose.optimized.yml logs -f
}

function Open-Shell {
    Write-ColorOutput $Blue "🖥️ Opening shell in app container..."
    docker exec -it laravel-app bash
}

function Run-Optimize {
    Write-ColorOutput $Green "⚡ Running Laravel optimizations..."
    docker exec laravel-app php artisan optimize
    docker exec laravel-app php artisan config:cache
    docker exec laravel-app php artisan route:cache
    docker exec laravel-app php artisan view:cache
    docker exec laravel-app php artisan event:cache
    Write-ColorOutput $Green "✅ Optimization complete!"
}

function Clear-Cache {
    Write-ColorOutput $Yellow "🧹 Clearing Laravel caches..."
    docker exec laravel-app php artisan optimize:clear
    Write-ColorOutput $Green "✅ Caches cleared!"
}

function Run-Migrations {
    Write-ColorOutput $Blue "📊 Running migrations..."
    docker exec laravel-app php artisan migrate
}

function Run-Tests {
    Write-ColorOutput $Blue "🧪 Running tests..."
    docker exec laravel-app php artisan test
}

function Check-OPcache {
    Write-ColorOutput $Blue "📊 OPcache Status:"
    docker exec laravel-app php -v | Select-String -Pattern "opcache"
    docker exec laravel-app php -r "echo 'OPcache Enabled: ' . (ini_get('opcache.enable') ? 'YES' : 'NO') . PHP_EOL;"
    docker exec laravel-app php -r "echo 'Validate Timestamps: ' . (ini_get('opcache.validate_timestamps') ? 'YES' : 'NO') . PHP_EOL;"
    docker exec laravel-app php -r "echo 'JIT: ' . ini_get('opcache.jit') . PHP_EOL;"
}

function Check-PHP {
    Write-ColorOutput $Blue "🐘 PHP Configuration:"
    docker exec laravel-app php -v
    Write-Output ""
    docker exec laravel-app php -i | Select-String -Pattern "(memory_limit|max_execution_time|upload_max_filesize|post_max_size)"
}

function Check-Health {
    Write-ColorOutput $Blue "❤️ Container Health Status:"
    docker-compose -f docker-compose.optimized.yml ps
}

function Install-Complete {
    Write-ColorOutput $Blue "📦 Running complete installation..."
    Build-Image
    Start-Containers
    Start-Sleep -Seconds 10
    Run-Migrations
    Run-Optimize
    Write-ColorOutput $Green "✅ Installation complete! Visit http://localhost:8080"
}

function Clean-All {
    Write-ColorOutput $Yellow "🧹 Removing all containers and volumes..."
    docker-compose -f docker-compose.optimized.yml down -v
    Write-ColorOutput $Green "✅ Cleanup complete!"
}

# Main command handler
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "build" { Build-Image }
    "build-prod" { Build-Prod }
    "build-dev" { Build-Dev }
    "up" { Start-Containers }
    "up-prod" { Start-Production }
    "up-dev" { Start-Development }
    "down" { Stop-Containers }
    "restart" { Restart-Containers }
    "logs" { Show-Logs }
    "shell" { Open-Shell }
    "optimize" { Run-Optimize }
    "clear-cache" { Clear-Cache }
    "migrate" { Run-Migrations }
    "test" { Run-Tests }
    "check-opcache" { Check-OPcache }
    "check-php" { Check-PHP }
    "health" { Check-Health }
    "install" { Install-Complete }
    "clean" { Clean-All }
    default {
        Write-ColorOutput $Red "❌ Unknown command: $Command"
        Write-Output ""
        Show-Help
    }
}

