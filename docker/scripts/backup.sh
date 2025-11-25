#!/bin/bash
# Database Backup Script for Lorekeeper
# This script creates automated MySQL backups

set -e

# Configuration from environment variables
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/lorekeeper_backup_${TIMESTAMP}.sql"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Starting database backup..."

# Perform backup
mysqldump -h "${DB_HOST}" \
          -u "${DB_USERNAME}" \
          -p"${DB_PASSWORD}" \
          --single-transaction \
          --routines \
          --triggers \
          --events \
          "${DB_DATABASE}" > "${BACKUP_FILE}"

# Compress backup
gzip "${BACKUP_FILE}"
BACKUP_FILE="${BACKUP_FILE}.gz"

echo "[$(date)] Backup created: ${BACKUP_FILE}"

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "[$(date)] Backup size: ${BACKUP_SIZE}"

# Remove old backups (keep only last N days)
echo "[$(date)] Removing backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "lorekeeper_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete

# List remaining backups
BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "lorekeeper_backup_*.sql.gz" -type f | wc -l)
echo "[$(date)] Total backups: ${BACKUP_COUNT}"

echo "[$(date)] Backup completed successfully!"
