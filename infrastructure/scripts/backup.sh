#!/bin/bash

###############################################################################
# Backup Script for FinNaslain Financial Solution
# This script backs up database and application data
###############################################################################

set -e

# Configuration
BACKUP_DIR="/var/backups/finnaslaim"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
S3_BUCKET="${DO_SPACES_BUCKET:-finnaslaim-backups}"
S3_ENDPOINT="${DO_SPACES_ENDPOINT:-https://nyc3.digitaloceanspaces.com}"

# Database configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-finnaslaim_production}"
DB_USER="${DB_USER:-finnaslaim}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

echo "=== Starting Backup Process ==="
echo "Timestamp: ${TIMESTAMP}"

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..."
PGPASSWORD="${DB_PASSWORD}" pg_dump \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    -F c \
    -f "${BACKUP_DIR}/db_${TIMESTAMP}.dump"

# Compress database backup
echo "Compressing database backup..."
gzip "${BACKUP_DIR}/db_${TIMESTAMP}.dump"

# Backup application files
echo "Backing up application files..."
tar -czf "${BACKUP_DIR}/app_${TIMESTAMP}.tar.gz" \
    -C /opt/finnaslaim \
    --exclude=node_modules \
    --exclude=logs \
    --exclude=.git \
    .

# Backup configuration files
echo "Backing up configuration files..."
tar -czf "${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz" \
    /etc/nginx/nginx.conf \
    /opt/finnaslaim/docker-compose.yml \
    /opt/finnaslaim/.env 2>/dev/null || true

# Upload to DigitalOcean Spaces (S3-compatible)
if command -v s3cmd &> /dev/null; then
    echo "Uploading backups to DigitalOcean Spaces..."
    s3cmd put \
        --host="${S3_ENDPOINT}" \
        --host-bucket="${S3_BUCKET}" \
        "${BACKUP_DIR}"/*_"${TIMESTAMP}"* \
        "s3://${S3_BUCKET}/backups/"
fi

# Remove old local backups
echo "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "*.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.dump" -mtime +${RETENTION_DAYS} -delete

# Generate backup report
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
echo "=== Backup Complete ==="
echo "Backup location: ${BACKUP_DIR}"
echo "Total backup size: ${BACKUP_SIZE}"
echo "Files created:"
ls -lh "${BACKUP_DIR}"/*"${TIMESTAMP}"*

# Send notification (optional)
if command -v mail &> /dev/null; then
    echo "Backup completed successfully at ${TIMESTAMP}" | \
        mail -s "FinNaslain Backup Report" admin@finnaslaim.com
fi

exit 0
