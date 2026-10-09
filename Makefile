.PHONY: help build build-noimagick build-xdebug size verify shell

IMAGE ?= cswni/laravel:8.4-dev
PHP_VERSION ?= 8.4
BUILD_ARGS ?=

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;32m%-16s\033[0m %s\n", $$1, $$2}'

build: ## Build the dev image (run on the Linux dev server)
	docker build --target dev --build-arg PHP_VERSION=$(PHP_VERSION) $(BUILD_ARGS) -t $(IMAGE) .

build-noimagick: ## Build without imagick (smaller; images via GD)
	$(MAKE) build BUILD_ARGS="--build-arg WITH_IMAGICK=0"

build-xdebug: ## Build with Xdebug installed (enable with XDEBUG_MODE=debug)
	$(MAKE) build BUILD_ARGS="--build-arg WITH_XDEBUG=1"

size: ## Show image size
	@docker images $(IMAGE) --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}'

verify: ## Check extensions, FrankenPHP and Swoole isolation
	@docker run --rm --entrypoint sh $(IMAGE) -c '\
	  set -e; \
	  frankenphp version; \
	  for e in bcmath exif gd intl opcache pcntl sockets zip pdo_mysql pdo_pgsql pgsql redis; do \
	    php -r "exit(extension_loaded(\"$$e\") ? 0 : 1);" && echo "OK      $$e" || { echo "MISSING $$e"; exit 1; }; \
	  done; \
	  php -r "echo extension_loaded(\"imagick\") ? \"OK      imagick\n\" : \"-       imagick (built without)\n\";"; \
	  php -r "exit(extension_loaded(\"swoole\") ? 1 : 0);" && echo "OK      swoole not loaded by default" || { echo "FAIL    swoole loaded by default"; exit 1; }; \
	  PHP_INI_SCAN_DIR="$$PHP_INI_DIR/conf.d:$$PHP_INI_DIR/conf.d-swoole" php -r "exit(extension_loaded(\"swoole\") ? 0 : 1);" && echo "OK      swoole loads in swoole mode" || { echo "FAIL    swoole missing in swoole mode"; exit 1; }'

shell: ## Open a shell in a throwaway container
	docker run --rm -it --entrypoint sh $(IMAGE)
