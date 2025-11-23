#!/bin/bash

###############################################################################
# Deployment Script for FinNaslain Financial Solution
# This script handles application deployment to DigitalOcean droplets
###############################################################################

set -e

# Configuration
APP_DIR="/opt/finnaslaim"
DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/tydera/cloud:latest}"
BACKUP_DIR="/var/backups/finnaslaim/deployments"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== FinNaslain Deployment Script ==="
echo "Timestamp: ${TIMESTAMP}"
echo "Docker Image: ${DOCKER_IMAGE}"
echo ""

# Function to log messages
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
    exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Pre-deployment checks
log "Running pre-deployment checks..."

# Check Docker
if ! systemctl is-active --quiet docker; then
    error "Docker is not running"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
if [ "${DISK_USAGE}" -gt 90 ]; then
    error "Disk usage is too high: ${DISK_USAGE}%"
    exit 1
fi

# Backup current deployment
log "Backing up current deployment..."
if [ -d "${APP_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/deployment_${TIMESTAMP}.tar.gz" -C "${APP_DIR}" .
    log "Backup created: ${BACKUP_DIR}/deployment_${TIMESTAMP}.tar.gz"
fi

# Pull latest Docker image
log "Pulling latest Docker image..."
docker pull "${DOCKER_IMAGE}"

# Stop current containers
log "Stopping current containers..."
cd "${APP_DIR}"
docker-compose down || true

# Start new containers
log "Starting new containers..."
export DOCKER_IMAGE="${DOCKER_IMAGE}"
docker-compose up -d

# Wait for containers to be healthy
log "Waiting for containers to be healthy..."
sleep 10

# Health check
MAX_ATTEMPTS=30
ATTEMPT=0
while [ ${ATTEMPT} -lt ${MAX_ATTEMPTS} ]; do
    if curl -f -s -o /dev/null http://localhost/health; then
        log "Health check passed!"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ ${ATTEMPT} -eq ${MAX_ATTEMPTS} ]; then
        error "Health check failed after ${MAX_ATTEMPTS} attempts"
        warning "Rolling back to previous deployment..."

        # Rollback
        docker-compose down
        tar -xzf "${BACKUP_DIR}/deployment_${TIMESTAMP}.tar.gz" -C "${APP_DIR}"
        docker-compose up -d

        error "Deployment failed and rolled back"
        exit 1
    fi
    sleep 2
done

# Clean up old Docker images
log "Cleaning up old Docker images..."
docker image prune -f

# Clean up old backups (keep last 10)
log "Cleaning up old backups..."
ls -t "${BACKUP_DIR}"/deployment_*.tar.gz | tail -n +11 | xargs rm -f || true

# Display running containers
log "Deployment successful! Running containers:"
docker ps --filter "name=finnaslaim"

echo ""
log "=== Deployment Complete ==="
log "Deployment time: ${TIMESTAMP}"
log "Application URL: http://$(hostname -I | awk '{print $1}')"

# Send notification
if command -v mail &> /dev/null; then
    echo "Deployment completed successfully at ${TIMESTAMP}" | \
        mail -s "FinNaslain Deployment Success" admin@finnaslaim.com
fi

exit 0
