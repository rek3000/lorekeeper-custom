# Lorekeeper Docker Setup Guide

This directory contains Docker configuration for running Lorekeeper locally with Docker and Docker Compose.

## 📋 Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 4GB of free RAM
- DeviantArt OAuth credentials (required for authentication)

## 🏗️ Architecture

The Docker setup includes the following services:

- **app**: PHP 8.1-FPM application container
- **webserver**: Nginx 1.x web server
- **db**: MySQL 8.0 database
- **redis**: Redis 7 for caching and queues
- **queue**: Laravel queue worker
- **scheduler**: Laravel task scheduler
- **mailhog**: Local email testing tool
- **node**: (optional) Node.js for asset compilation

## 🚀 Quick Start

### 1. Initial Setup

Run the automated setup script:

```bash
./docker-setup.sh
```

This script will:
- Create `.env` file from `.env.docker`
- Generate application key
- Start database and Redis
- Run migrations
- Seed initial data
- Start all services

### 2. Create Admin User

After setup completes, create your admin account:

```bash
docker-compose exec app php artisan setup-admin-user
```

Follow the prompts to create your admin user.

### 3. Configure OAuth Credentials

Edit `.env` file and add your DeviantArt OAuth credentials:

```env
DEVIANTART_KEY=your_client_id
DEVIANTART_SECRET=your_client_secret
DEVIANTART_REDIRECT_URI=http://localhost/auth/callback/deviantart
```

Then restart the services:

```bash
docker-compose restart
```

### 4. Access the Application

- **Web Application**: http://localhost
- **MailHog UI**: http://localhost:8025 (for viewing test emails)

## 🔧 Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Environment Configuration

```bash
# Copy environment file
cp .env.docker .env

# Edit .env and configure your settings
nano .env
```

### 2. Build and Start Services

```bash
# Build containers
docker-compose build

# Start services
docker-compose up -d

# Wait for database to be ready
sleep 10
```

### 3. Install Dependencies

```bash
# Install Composer dependencies
docker-compose exec app composer install

# Generate application key
docker-compose exec app php artisan key:generate
```

### 4. Database Setup

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Add initial data
docker-compose exec app php artisan add-site-settings
docker-compose exec app php artisan add-text-pages
docker-compose exec app php artisan copy-default-images

# Create storage symlink
docker-compose exec app php artisan storage:link
```

### 5. Cache Configuration

```bash
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
```

## 📚 Common Commands

### Application Management

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f webserver

# Restart all services
docker-compose restart

# Stop all services
docker-compose down

# Stop and remove volumes (⚠️  deletes data)
docker-compose down -v
```

### Laravel Artisan Commands

```bash
# Run any artisan command
docker-compose exec app php artisan [command]

# Examples:
docker-compose exec app php artisan migrate
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan queue:work
docker-compose exec app php artisan tinker
```

### Database Access

```bash
# Access MySQL CLI
docker-compose exec db mysql -u lorekeeper -p

# Export database
docker-compose exec db mysqldump -u lorekeeper -p lorekeeper > backup.sql

# Import database
docker-compose exec -T db mysql -u lorekeeper -p lorekeeper < backup.sql
```

### File Permissions

If you encounter permission issues:

```bash
# Fix storage permissions
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chmod -R 775 /var/www/html/storage

# Fix bootstrap/cache permissions
docker-compose exec app chown -R www-data:www-data /var/www/html/bootstrap/cache
docker-compose exec app chmod -R 775 /var/www/html/bootstrap/cache
```

### Asset Compilation

For frontend asset development:

```bash
# Start Node.js container for watching assets
docker-compose --profile dev up -d node

# Or compile assets manually
docker-compose run --rm node npm install
docker-compose run --rm node npm run dev

# For production
docker-compose run --rm node npm run production
```

### Container Shell Access

```bash
# Access app container shell
docker-compose exec app bash

# Access database container shell
docker-compose exec db bash

# Access as root user
docker-compose exec -u root app bash
```

## 🐛 Troubleshooting

### Container won't start

```bash
# Check container status
docker-compose ps

# Check logs for errors
docker-compose logs app
docker-compose logs db
```

### Database connection errors

```bash
# Ensure database is ready
docker-compose exec db mysqladmin ping -h localhost -u root -p

# Check database credentials in .env
cat .env | grep DB_
```

### Permission denied errors

```bash
# Reset permissions
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/storage
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/bootstrap/cache
```

### Port already in use

If port 80 is already in use, edit `.env`:

```env
WEB_PORT=8080  # Change to any available port
```

Then restart:

```bash
docker-compose down
docker-compose up -d
```

### Clear all caches

```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

## 🔒 Security Notes

### For Local Development

The default configuration is optimized for local development and includes:
- MailHog for email testing (not suitable for production)
- Debug mode enabled
- Simple passwords (change these!)

### For Production

Do NOT use this configuration as-is for production. You should:

1. Use strong passwords for database and Redis
2. Disable debug mode (`APP_DEBUG=false`)
3. Use a real mail service (not MailHog)
4. Configure SSL/TLS certificates
5. Use environment-specific secrets
6. Enable additional security headers
7. Configure proper backup strategies

## 📖 Environment Variables Reference

### Application

- `APP_NAME`: Application name
- `APP_ENV`: Environment (local, production)
- `APP_KEY`: Encryption key (auto-generated)
- `APP_DEBUG`: Debug mode (true/false)
- `APP_URL`: Application URL

### Database

- `DB_CONNECTION`: Database driver (mysql)
- `DB_HOST`: Database host (db)
- `DB_PORT`: Database port (3306)
- `DB_DATABASE`: Database name
- `DB_USERNAME`: Database user
- `DB_PASSWORD`: Database password

### Cache & Queue

- `CACHE_DRIVER`: Cache driver (redis)
- `SESSION_DRIVER`: Session driver (redis)
- `QUEUE_CONNECTION`: Queue driver (redis)

### Redis

- `REDIS_HOST`: Redis host (redis)
- `REDIS_PASSWORD`: Redis password (null for no auth)
- `REDIS_PORT`: Redis port (6379)

### Mail

- `MAIL_DRIVER`: Mail driver (smtp)
- `MAIL_HOST`: SMTP host
- `MAIL_PORT`: SMTP port
- `MAIL_USERNAME`: SMTP username
- `MAIL_PASSWORD`: SMTP password

### Lorekeeper Specific

- `CONTACT_ADDRESS`: Contact email
- `DEVIANTART_ACCOUNT`: DeviantArt group account
- `DEVIANTART_KEY`: DeviantArt OAuth client ID
- `DEVIANTART_SECRET`: DeviantArt OAuth client secret

## 🤝 Contributing

If you find issues with the Docker setup or have improvements, please contribute!

## 📄 License

This Docker configuration is provided as-is for the Lorekeeper project.
