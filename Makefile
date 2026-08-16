.PHONY: help build build-prod build-dev up up-prod up-dev down restart logs shell test optimize clear-cache check-opcache bench

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '$(BLUE)Laravel FrankenPHP - Available Commands:$(NC)'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ''

# Build Commands
build: ## Build the optimized Docker image
	@echo '$(BLUE)Building optimized Docker image...$(NC)'
	docker build -f Dockerfile.optimized -t laravel-frankenphp:latest .

build-prod: ## Build for production
	@echo '$(BLUE)Building production image...$(NC)'
	docker build -f Dockerfile.optimized -t laravel-frankenphp:production .

build-dev: ## Build for development
	@echo '$(BLUE)Building development image...$(NC)'
	docker build -f Dockerfile.optimized -t cswni/fphp:0.0.1 .

# Run Commands
up: ## Start all containers
	@echo '$(BLUE)Starting containers...$(NC)'
	docker-compose -f docker-compose.optimized.yml up -d

up-prod: ## Start in production mode
	@echo '$(BLUE)Starting in PRODUCTION mode...$(NC)'
	cp .env.production.example .env || true
	docker-compose -f docker-compose.optimized.yml up -d --build

up-dev: ## Start in development mode
	@echo '$(BLUE)Starting in DEVELOPMENT mode...$(NC)'
	cp .env.development.example .env || true
	docker-compose -f docker-compose.optimized.yml up -d --build

down: ## Stop all containers
	@echo '$(YELLOW)Stopping containers...$(NC)'
	docker-compose -f docker-compose.optimized.yml down

restart: ## Restart all containers
	@echo '$(YELLOW)Restarting containers...$(NC)'
	docker-compose -f docker-compose.optimized.yml restart

# Utility Commands
logs: ## Show container logs
	docker-compose -f docker-compose.optimized.yml logs -f

shell: ## Open shell in app container
	@echo '$(BLUE)Opening shell in app container...$(NC)'
	docker exec -it laravel-app bash

shell-root: ## Open shell as root in app container
	@echo '$(BLUE)Opening shell as root in app container...$(NC)'
	docker exec -it -u root laravel-app bash

# Laravel Commands
optimize: ## Run Laravel optimizations
	@echo '$(GREEN)Running Laravel optimizations...$(NC)'
	docker exec laravel-app php artisan optimize
	docker exec laravel-app php artisan config:cache
	docker exec laravel-app php artisan route:cache
	docker exec laravel-app php artisan view:cache
	docker exec laravel-app php artisan event:cache
	@echo '$(GREEN)✅ Optimization complete!$(NC)'

clear-cache: ## Clear all Laravel caches
	@echo '$(YELLOW)Clearing Laravel caches...$(NC)'
	docker exec laravel-app php artisan optimize:clear
	@echo '$(GREEN)✅ Caches cleared!$(NC)'

migrate: ## Run database migrations
	@echo '$(BLUE)Running migrations...$(NC)'
	docker exec laravel-app php artisan migrate

migrate-fresh: ## Fresh migration with seeding
	@echo '$(YELLOW)Running fresh migrations with seed...$(NC)'
	docker exec laravel-app php artisan migrate:fresh --seed

# Testing & Monitoring
test: ## Run PHPUnit tests
	@echo '$(BLUE)Running tests...$(NC)'
	docker exec laravel-app php artisan test

check-opcache: ## Check OPcache status
	@echo '$(BLUE)OPcache Status:$(NC)'
	@docker exec laravel-app php -v | grep -i opcache
	@echo ''
	@docker exec laravel-app php -r "echo 'OPcache Enabled: ' . (ini_get('opcache.enable') ? 'YES' : 'NO') . PHP_EOL;"
	@docker exec laravel-app php -r "echo 'Validate Timestamps: ' . (ini_get('opcache.validate_timestamps') ? 'YES' : 'NO') . PHP_EOL;"
	@docker exec laravel-app php -r "echo 'JIT: ' . ini_get('opcache.jit') . PHP_EOL;"

check-php: ## Show PHP configuration
	@echo '$(BLUE)PHP Configuration:$(NC)'
	docker exec laravel-app php -v
	@echo ''
	docker exec laravel-app php -i | grep -E "(memory_limit|max_execution_time|upload_max_filesize|post_max_size)"

health: ## Check container health
	@echo '$(BLUE)Container Health Status:$(NC)'
	docker-compose -f docker-compose.optimized.yml ps

bench: ## Run basic performance benchmark
	@echo '$(BLUE)Running performance benchmark...$(NC)'
	@echo 'Testing 1000 requests with 10 concurrent connections...'
	ab -n 1000 -c 10 http://localhost:8080/ || echo "$(YELLOW)Install apache2-utils for benchmarking$(NC)"

# Composer Commands
composer-install: ## Run composer install
	@echo '$(BLUE)Running composer install...$(NC)'
	docker exec laravel-app composer install --optimize-autoloader --no-dev

composer-update: ## Run composer update
	@echo '$(BLUE)Running composer update...$(NC)'
	docker exec laravel-app composer update

composer-dump: ## Dump composer autoload
	@echo '$(BLUE)Dumping composer autoload...$(NC)'
	docker exec laravel-app composer dump-autoload -o

# Cleanup Commands
clean: ## Remove all containers and volumes
	@echo '$(YELLOW)Removing all containers and volumes...$(NC)'
	docker-compose -f docker-compose.optimized.yml down -v
	@echo '$(GREEN)✅ Cleanup complete!$(NC)'

prune: ## Prune Docker system
	@echo '$(YELLOW)Pruning Docker system...$(NC)'
	docker system prune -af
	@echo '$(GREEN)✅ Prune complete!$(NC)'

# Installation
install: build up migrate optimize ## Complete installation (build, up, migrate, optimize)
	@echo '$(GREEN)✅ Installation complete! Visit http://localhost:8080$(NC)'

# Production deployment
deploy-prod: build-prod ## Deploy to production
	@echo '$(GREEN)Deploying to production...$(NC)'
	docker-compose -f docker-compose.optimized.yml down
	docker-compose -f docker-compose.optimized.yml up -d --build
	sleep 10
	$(MAKE) migrate
	$(MAKE) optimize
	@echo '$(GREEN)✅ Production deployment complete!$(NC)'

