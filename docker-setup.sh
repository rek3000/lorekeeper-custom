#!/bin/bash

# Lorekeeper Docker Setup Script
# This script helps you set up the Lorekeeper application with Docker

set -e

echo "==========================================="
echo "Lorekeeper Docker Setup"
echo "==========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.docker..."
    cp .env.docker .env
    echo "✅ .env file created"
else
    echo "⚠️  .env file already exists, skipping..."
fi

# Generate APP_KEY if not set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "🔑 Generating application key..."
    
    # Build app container first to generate key
    docker-compose build app
    
    # Generate key
    docker-compose run --rm app php artisan key:generate
    echo "✅ Application key generated"
else
    echo "✅ Application key already set"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p storage/logs
mkdir -p bootstrap/cache
chmod -R 775 storage bootstrap/cache
echo "✅ Directories created"

# Start Docker containers
echo "🐳 Starting Docker containers..."
docker-compose up -d db redis
echo "⏳ Waiting for database to be ready..."
sleep 10

# Run migrations
echo "🔄 Running database migrations..."
docker-compose run --rm app php artisan migrate --force

# Seed database with initial data
echo "🌱 Adding site settings and default data..."
docker-compose run --rm app php artisan add-site-settings || echo "⚠️  Site settings might already exist"
docker-compose run --rm app php artisan add-text-pages || echo "⚠️  Text pages might already exist"
docker-compose run --rm app php artisan copy-default-images || echo "⚠️  Default images might already exist"

# Set up storage link
echo "🔗 Creating storage symlink..."
docker-compose run --rm app php artisan storage:link || echo "⚠️  Storage link might already exist"

# Cache configuration
echo "⚡ Caching configuration..."
docker-compose run --rm app php artisan config:cache
docker-compose run --rm app php artisan route:cache
docker-compose run --rm app php artisan view:cache

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

echo ""
echo "==========================================="
echo "✅ Setup complete!"
echo "==========================================="
echo ""
echo "📋 Services running:"
echo "   - Web Application: http://localhost"
echo "   - MailHog (Email): http://localhost:8025"
echo "   - Database: localhost:3306"
echo "   - Redis: localhost:6379"
echo ""
echo "🔧 Next steps:"
echo "   1. Run: docker-compose exec app php artisan setup-admin-user"
echo "      (to create your admin account)"
echo "   2. Configure your social OAuth credentials in .env"
echo "   3. Restart containers: docker-compose restart"
echo ""
echo "📚 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Stop services: docker-compose down"
echo "   - Restart services: docker-compose restart"
echo "   - Run artisan: docker-compose exec app php artisan [command]"
echo "   - Access shell: docker-compose exec app bash"
echo ""
