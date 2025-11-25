# Lorekeeper Docker Setup Guide

This guide provides complete step-by-step instructions for running Lorekeeper from scratch using Docker.

## 📋 Prerequisites

Before you begin, ensure you have:

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 4GB of free RAM
- Git installed
- DeviantArt OAuth credentials (required for authentication)

### Installing Docker

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**macOS/Windows:**
Download and install Docker Desktop from https://www.docker.com/products/docker-desktop

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

## 🚀 Quick Start (From Scratch)

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-username/lorekeeper.git
cd lorekeeper
```

### Step 2: Run the Automated Setup

Run the setup script that handles everything automatically:

```bash
chmod +x docker-setup.sh
./docker-setup.sh
```

This script will:
- ✅ Create `.env` file from `.env.docker`
- ✅ Build Docker images
- ✅ Start database and Redis
- ✅ Install Composer dependencies (including predis/predis)
- ✅ Generate application key
- ✅ Run migrations
- ✅ Seed initial data
- ✅ Create storage symlink
- ✅ Cache configuration
- ✅ Start all services

**Note:** The setup process takes 5-10 minutes depending on your internet connection.

### Step 3: Fix Permissions (Important!)

After setup, fix file permissions to avoid log errors:

```bash
make permissions
```

Or manually:
```bash
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/storage
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/bootstrap/cache
docker-compose exec -u root app chmod -R 775 /var/www/html/storage
docker-compose exec -u root app chmod -R 775 /var/www/html/bootstrap/cache
```

### Step 4: Create Admin User

Create your admin account:

```bash
docker-compose exec app php artisan setup-admin-user
```

Follow the prompts to:
- Enter admin username
- Enter admin email
- Set admin password

### Step 5: Configure OAuth Credentials (Optional but Recommended)

Edit `.env` file and add your DeviantArt OAuth credentials:

```env
DEVIANTART_KEY=your_client_id
DEVIANTART_SECRET=your_client_secret
DEVIANTART_REDIRECT_URI=http://localhost/auth/callback/deviantart
```

To get DeviantArt OAuth credentials:
1. Go to https://www.deviantart.com/developers/
2. Create a new application
3. Copy the Client ID and Client Secret

Then restart the services:

```bash
docker-compose restart
```

### Step 6: Access the Application

Your application is now running at:

- **Web Application**: http://localhost
- **MailHog UI**: http://localhost:8025 (for viewing test emails)
- **MySQL**: localhost:3306
- **Redis**: localhost:6379

### Step 7: Verify Everything Works

```bash
# Check all services are running
docker-compose ps

# Check logs if any issues
docker-compose logs -f app

# Test the application by visiting http://localhost
```

## 🎯 Quick Start Using Make Commands

If you have `make` installed, use these convenient shortcuts:

```bash
make setup       # Run initial setup
make permissions # Fix file permissions
make up          # Start all services
make shell       # Access app container
make logs        # View logs
```

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
# Install Composer dependencies (including predis/predis for Redis)
docker-compose exec app composer install
docker-compose exec app composer require predis/predis

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

### "Class 'Predis\Client' not found" Error

This means the Redis client library is missing:

```bash
# Install predis package
docker-compose exec app composer require predis/predis

# Clear config cache
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
```

### "NOAUTH Authentication required" Redis Error

This happens when Redis password configuration is mismatched:

**Solution 1: Remove Redis password (for local development)**
1. Edit `docker-compose.yml` and remove the `command:` line under the redis service
2. Recreate Redis container:
```bash
docker-compose stop redis
docker-compose rm -f redis
docker-compose up -d redis
```

**Solution 2: Set a proper Redis password**
1. Edit `.env` and set `REDIS_PASSWORD=your_secure_password`
2. Edit `docker-compose.yml` and change command to: `redis-server --requirepass your_secure_password`
3. Restart services: `docker-compose restart`

### Permission denied errors (Laravel log files)

**Error:** `The stream or file "storage/logs/laravel.log" could not be opened`

**Solution:**
```bash
# Fix permissions using make command
make permissions

# Or manually:
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/storage
docker-compose exec -u root app chown -R www-data:www-data /var/www/html/bootstrap/cache
docker-compose exec -u root app chmod -R 775 /var/www/html/storage
docker-compose exec -u root app chmod -R 775 /var/www/html/bootstrap/cache
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
