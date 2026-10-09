.PHONY: help build build-prod size verify

BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

IMAGE ?= cswni/laravel-swoole:8.4
DOCKERFILE ?= Dockerfile

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-16s$(NC) %s\n", $$1, $$2}'

build: ## Build lean PHP 8.4 + Swoole runtime
	@echo '$(BLUE)Building $(IMAGE)...$(NC)'
	docker build -f $(DOCKERFILE) -t $(IMAGE) .

build-prod: build ## Alias for build

size: ## Show image size
	@docker images $(IMAGE) --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}'

verify: ## php -m + swoole/redis/imagick sanity
	@docker run --rm --entrypoint php $(IMAGE) -m | sort
	@docker run --rm --entrypoint php $(IMAGE) -r 'foreach (["swoole","redis","imagick","pdo_pgsql","intl","pcntl"] as $$e) { echo $$e, extension_loaded($$e) ? " OK\n" : " MISSING\n"; }'
