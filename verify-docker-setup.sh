#!/bin/bash
# Verification script for Docker setup

echo "🔍 Verifying Lorekeeper Docker Setup..."
echo ""

errors=0

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed: $(docker --version)"
else
    echo "❌ Docker is NOT installed"
    ((errors++))
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "✅ Docker Compose is installed"
else
    echo "❌ Docker Compose is NOT installed"
    ((errors++))
fi

# Check required files
files=(
    "docker-compose.yml"
    "Dockerfile"
    ".dockerignore"
    ".env.docker"
    "docker-setup.sh"
    "docker/nginx/nginx.conf"
    "Makefile"
)

for file in "${files[@]}"; do
    if [ -f "$file" ] || [ -d "$(dirname "$file")" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        ((errors++))
    fi
done

# Check if .env exists
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    
    # Check for APP_KEY
    if grep -q "APP_KEY=base64:" .env; then
        echo "✅ APP_KEY is set"
    else
        echo "⚠️  APP_KEY not generated yet (run docker-setup.sh)"
    fi
    
    # Check for DeviantArt credentials
    if grep -q "DEVIANTART_KEY=.\+" .env && ! grep -q "DEVIANTART_KEY=$" .env; then
        echo "✅ DeviantArt credentials configured"
    else
        echo "⚠️  DeviantArt credentials not configured"
    fi
else
    echo "⚠️  .env file not created yet (will be created by setup script)"
fi

echo ""
if [ $errors -eq 0 ]; then
    echo "✅ All checks passed! You're ready to run: ./docker-setup.sh"
else
    echo "❌ Found $errors errors. Please fix them before proceeding."
    exit 1
fi
