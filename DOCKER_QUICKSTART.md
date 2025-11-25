# Lorekeeper Docker Quick Reference

## 🚀 First Time Setup

```bash
./docker-setup.sh
docker-compose exec app php artisan setup-admin-user
```

## 🎮 Daily Commands

```bash
make up              # Start all services
make down            # Stop all services
make restart         # Restart services
make logs            # View all logs
make logs service=app # View specific service
make shell           # Access app container
```

## 🔨 Development

```bash
make artisan cmd="migrate"        # Run artisan command
make migrate                      # Run migrations
make cache-clear                  # Clear all caches
make npm-watch                    # Watch assets
```

## 💾 Database

```bash
make db-shell                     # MySQL shell
make backup-db                    # Backup database
make restore-db file=backup.sql   # Restore database
```

## 📦 Without Make

```bash
docker-compose up -d                           # Start
docker-compose down                            # Stop
docker-compose logs -f                         # Logs
docker-compose exec app bash                   # Shell
docker-compose exec app php artisan [cmd]      # Artisan
```

## 🌐 Access Points

- **Web**: http://localhost
- **Mail**: http://localhost:8025

## 📝 Important Files

- `.env` - Your configuration
- `docker-compose.yml` - Service definitions
- `DOCKER.md` - Full documentation
- `DOCKER_SETUP_SUMMARY.md` - Complete guide

## ⚙️ Configure Before First Use

Edit `.env` and add:
```env
DEVIANTART_KEY=your_key
DEVIANTART_SECRET=your_secret
CONTACT_ADDRESS=admin@example.com
```

## 🔧 Troubleshooting

```bash
make permissions     # Fix file permissions
make clean          # Nuclear option (deletes data!)
make cache-clear    # Clear Laravel caches
docker-compose ps   # Check service status
```

## 📊 Status Check

```bash
docker-compose ps              # Services status
make stats                     # Resource usage
docker-compose logs app        # App logs
docker-compose exec db mysqladmin ping -h localhost -u root -p
```
