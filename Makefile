.PHONY: help build build-builder build-prod build-all build-noimagick build-xdebug size verify verify-all shell

REPO ?= cswni/laravel
PHP_VERSION ?= 8.4
IMAGE ?= $(REPO):$(PHP_VERSION)-dev
BUILD_ARGS ?=

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;32m%-16s\033[0m %s\n", $$1, $$2}'

build: ## Build the dev image (bind-mounted code, watcher)
	docker build --target dev --build-arg PHP_VERSION=$(PHP_VERSION) $(BUILD_ARGS) -t $(REPO):$(PHP_VERSION)-dev .

build-builder: ## Build the Composer image for app vendor stages
	docker build --target builder --build-arg PHP_VERSION=$(PHP_VERSION) $(BUILD_ARGS) -t $(REPO):$(PHP_VERSION)-builder .

build-prod: ## Build the runtime base for per-deploy app images
	docker build --target prod --build-arg PHP_VERSION=$(PHP_VERSION) $(BUILD_ARGS) -t $(REPO):$(PHP_VERSION)-prod .

build-all: build build-builder build-prod ## Build dev, builder and prod

build-noimagick: ## Build without imagick (smaller; images via GD)
	$(MAKE) build BUILD_ARGS="--build-arg WITH_IMAGICK=0"

build-xdebug: ## Build with Xdebug installed (enable with XDEBUG_MODE=debug)
	$(MAKE) build BUILD_ARGS="--build-arg WITH_XDEBUG=1"

size: ## Show image sizes
	@docker images $(REPO) --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}'

verify: ## Check extensions, FrankenPHP and Swoole isolation (IMAGE=...)
	@echo "== $(IMAGE)"
	@docker run --rm --entrypoint sh $(IMAGE) -c '\
	  set -e; \
	  frankenphp version; \
	  echo "APP_ENV=$${APP_ENV}  validate_timestamps=$$(php -r "echo ini_get(\"opcache.validate_timestamps\");")  jit=$$(php -r "echo ini_get(\"opcache.jit\");")"; \
	  php -r "exit(extension_loaded(\"Zend OPcache\") ? 0 : 1);" && echo "OK      opcache" || { echo "MISSING opcache"; exit 1; }; \
	  for e in bcmath exif gd intl pcntl sockets zip pdo_mysql pdo_pgsql pgsql redis; do \
	    php -r "exit(extension_loaded(\"$$e\") ? 0 : 1);" && echo "OK      $$e" || { echo "MISSING $$e"; exit 1; }; \
	  done; \
	  php -r "echo extension_loaded(\"imagick\") ? \"OK      imagick\n\" : \"-       imagick (built without)\n\";"; \
	  php -r "exit(extension_loaded(\"swoole\") ? 1 : 0);" && echo "OK      swoole not loaded by default" || { echo "FAIL    swoole loaded by default"; exit 1; }; \
	  PHP_INI_SCAN_DIR="$$PHP_INI_DIR/conf.d:$$PHP_INI_DIR/conf.d-swoole" php -r "exit(extension_loaded(\"swoole\") ? 0 : 1);" && echo "OK      swoole loads in swoole mode" || { echo "FAIL    swoole missing in swoole mode"; exit 1; }'

verify-all: ## Verify dev, builder and prod
	@for t in dev builder prod; do $(MAKE) -s verify IMAGE=$(REPO):$(PHP_VERSION)-$$t || exit 1; done

shell: ## Open a shell in a throwaway container
	docker run --rm -it --entrypoint sh $(IMAGE)
