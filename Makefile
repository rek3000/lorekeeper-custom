.PHONY: help build up down restart logs shell artisan migrate fresh seed setup admin clean

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Lorekeeper Docker Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

build: ## Build all Docker containers
	@echo "$(BLUE)Building Docker containers...$(NC)"
	docker-compose build

up: ## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ Services started!$(NC)"
	@echo "$(YELLOW)Web: http://localhost$(NC)"
	@echo "$(YELLOW)MailHog: http://localhost:8025$(NC)"

down: ## Stop all services
	@echo "$(RED)Stopping all services...$(NC)"
	docker-compose down

restart: ## Restart all services
	@echo "$(YELLOW)Restarting services...$(NC)"
	docker-compose restart
	@echo "$(GREEN)✅ Services restarted!$(NC)"

logs: ## Show logs (use 'make logs service=app' for specific service)
	@if [ -z "$(service)" ]; then \
		docker-compose logs -f; \
	else \
		docker-compose logs -f $(service); \
	fi

shell: ## Access app container shell
	@echo "$(BLUE)Accessing app container...$(NC)"
	docker-compose exec app bash

db-shell: ## Access database shell
	@echo "$(BLUE)Accessing database...$(NC)"
	docker-compose exec db mysql -u lorekeeper -p

artisan: ## Run artisan command (use 'make artisan cmd="migrate"')
	@if [ -z "$(cmd)" ]; then \
		echo "$(RED)Usage: make artisan cmd=\"your-command\"$(NC)"; \
		exit 1; \
	fi
	docker-compose exec app php artisan $(cmd)

migrate: ## Run database migrations
	@echo "$(BLUE)Running migrations...$(NC)"
	docker-compose exec app php artisan migrate
	@echo "$(GREEN)✅ Migrations completed!$(NC)"

fresh: ## Fresh database with migrations
	@echo "$(RED)⚠️  This will drop all tables!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose exec app php artisan migrate:fresh; \
	fi

seed: ## Run database seeders
	@echo "$(BLUE)Running seeders...$(NC)"
	docker-compose exec app php artisan db:seed
	@echo "$(GREEN)✅ Seeding completed!$(NC)"

setup: ## Initial setup (first time only)
	@echo "$(GREEN)Running initial setup...$(NC)"
	@chmod +x docker-setup.sh
	./docker-setup.sh

admin: ## Create admin user
	@echo "$(BLUE)Creating admin user...$(NC)"
	docker-compose exec app php artisan setup-admin-user

cache-clear: ## Clear all caches
	@echo "$(BLUE)Clearing caches...$(NC)"
	docker-compose exec app php artisan cache:clear
	docker-compose exec app php artisan config:clear
	docker-compose exec app php artisan route:clear
	docker-compose exec app php artisan view:clear
	@echo "$(GREEN)✅ Caches cleared!$(NC)"

cache-build: ## Build all caches
	@echo "$(BLUE)Building caches...$(NC)"
	docker-compose exec app php artisan config:cache
	docker-compose exec app php artisan route:cache
	docker-compose exec app php artisan view:cache
	@echo "$(GREEN)✅ Caches built!$(NC)"

npm-install: ## Install npm dependencies
	@echo "$(BLUE)Installing npm dependencies...$(NC)"
	docker-compose run --rm node npm install
	@echo "$(GREEN)✅ npm packages installed!$(NC)"

npm-dev: ## Compile assets for development
	@echo "$(BLUE)Compiling assets (dev)...$(NC)"
	docker-compose run --rm node npm run dev

npm-watch: ## Watch and compile assets
	@echo "$(BLUE)Watching assets for changes...$(NC)"
	docker-compose --profile dev up node

npm-prod: ## Compile assets for production
	@echo "$(BLUE)Compiling assets (production)...$(NC)"
	docker-compose run --rm node npm run production

composer-install: ## Install composer dependencies
	@echo "$(BLUE)Installing composer dependencies...$(NC)"
	docker-compose exec app composer install
	@echo "$(GREEN)✅ Composer packages installed!$(NC)"

composer-update: ## Update composer dependencies
	@echo "$(BLUE)Updating composer dependencies...$(NC)"
	docker-compose exec app composer update

permissions: ## Fix file permissions
	@echo "$(BLUE)Fixing permissions...$(NC)"
	docker-compose exec -u root app chown -R www-data:www-data /var/www/html/storage
	docker-compose exec -u root app chown -R www-data:www-data /var/www/html/bootstrap/cache
	docker-compose exec -u root app chmod -R 775 /var/www/html/storage
	docker-compose exec -u root app chmod -R 775 /var/www/html/bootstrap/cache
	@echo "$(GREEN)✅ Permissions fixed!$(NC)"

backup-db: ## Backup database to backup.sql
	@echo "$(BLUE)Backing up database...$(NC)"
	docker-compose exec db mysqldump -u lorekeeper -p lorekeeper > backup-$(shell date +%Y%m%d-%H%M%S).sql
	@echo "$(GREEN)✅ Database backed up!$(NC)"

restore-db: ## Restore database from backup.sql
	@if [ ! -f "$(file)" ]; then \
		echo "$(RED)Usage: make restore-db file=backup.sql$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restoring database...$(NC)"
	docker-compose exec -T db mysql -u lorekeeper -p lorekeeper < $(file)
	@echo "$(GREEN)✅ Database restored!$(NC)"

clean: ## Clean up containers and volumes
	@echo "$(RED)⚠️  This will remove all containers and volumes!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "$(GREEN)✅ Cleanup completed!$(NC)"; \
	fi

ps: ## Show running containers
	docker-compose ps

stats: ## Show container resource usage
	docker stats $$(docker-compose ps -q)
