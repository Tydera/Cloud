#!/bin/bash

###############################################################################
# Monitoring Script for FinNaslain Financial Solution
# This script monitors system health and sends alerts
###############################################################################

set -e

# Configuration
ALERT_EMAIL="${ALERT_EMAIL:-admin@finnaslaim.com}"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=85
LOAD_THRESHOLD=4.0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== System Health Check ==="
echo "Server: ${HOSTNAME}"
echo "Time: ${TIMESTAMP}"
echo ""

ALERTS=""

# Check CPU usage
echo "Checking CPU usage..."
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
CPU_USAGE_INT=${CPU_USAGE%.*}
if [ "${CPU_USAGE_INT}" -gt "${CPU_THRESHOLD}" ]; then
    echo -e "${RED}[ALERT]${NC} CPU usage is high: ${CPU_USAGE}%"
    ALERTS="${ALERTS}\n- CPU usage is high: ${CPU_USAGE}%"
else
    echo -e "${GREEN}[OK]${NC} CPU usage: ${CPU_USAGE}%"
fi

# Check memory usage
echo "Checking memory usage..."
MEMORY_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
MEMORY_USAGE_INT=${MEMORY_USAGE%.*}
if [ "${MEMORY_USAGE_INT}" -gt "${MEMORY_THRESHOLD}" ]; then
    echo -e "${RED}[ALERT]${NC} Memory usage is high: ${MEMORY_USAGE}%"
    ALERTS="${ALERTS}\n- Memory usage is high: ${MEMORY_USAGE}%"
else
    echo -e "${GREEN}[OK]${NC} Memory usage: ${MEMORY_USAGE}%"
fi

# Check disk usage
echo "Checking disk usage..."
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
if [ "${DISK_USAGE}" -gt "${DISK_THRESHOLD}" ]; then
    echo -e "${RED}[ALERT]${NC} Disk usage is high: ${DISK_USAGE}%"
    ALERTS="${ALERTS}\n- Disk usage is high: ${DISK_USAGE}%"
else
    echo -e "${GREEN}[OK]${NC} Disk usage: ${DISK_USAGE}%"
fi

# Check load average
echo "Checking load average..."
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
if (( $(echo "${LOAD_AVG} > ${LOAD_THRESHOLD}" | bc -l) )); then
    echo -e "${YELLOW}[WARNING]${NC} Load average is high: ${LOAD_AVG}"
    ALERTS="${ALERTS}\n- Load average is high: ${LOAD_AVG}"
else
    echo -e "${GREEN}[OK]${NC} Load average: ${LOAD_AVG}"
fi

# Check if Docker is running
echo "Checking Docker service..."
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}[OK]${NC} Docker is running"
else
    echo -e "${RED}[ALERT]${NC} Docker is not running"
    ALERTS="${ALERTS}\n- Docker service is not running"
fi

# Check if application containers are running
echo "Checking application containers..."
APP_CONTAINERS=$(docker ps --filter "name=finnaslaim" --format "{{.Names}}" 2>/dev/null || echo "")
if [ -n "${APP_CONTAINERS}" ]; then
    echo -e "${GREEN}[OK]${NC} Application containers are running:"
    echo "${APP_CONTAINERS}"
else
    echo -e "${RED}[ALERT]${NC} No application containers are running"
    ALERTS="${ALERTS}\n- No application containers are running"
fi

# Check database connectivity
echo "Checking database connectivity..."
if docker exec -it $(docker ps -q -f name=postgres) pg_isready -U ${DB_USER:-finnaslaim} &>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Database is accessible"
else
    echo -e "${RED}[ALERT]${NC} Database is not accessible"
    ALERTS="${ALERTS}\n- Database is not accessible"
fi

# Check application health endpoint
echo "Checking application health..."
if curl -f -s -o /dev/null http://localhost/health; then
    echo -e "${GREEN}[OK]${NC} Application health check passed"
else
    echo -e "${RED}[ALERT]${NC} Application health check failed"
    ALERTS="${ALERTS}\n- Application health check failed"
fi

# Check SSL certificate expiration
echo "Checking SSL certificate..."
if [ -f "/etc/nginx/ssl/cert.pem" ]; then
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in /etc/nginx/ssl/cert.pem | cut -d= -f2)
    CERT_EXPIRY_EPOCH=$(date -d "${CERT_EXPIRY}" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( (CERT_EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

    if [ "${DAYS_UNTIL_EXPIRY}" -lt 30 ]; then
        echo -e "${YELLOW}[WARNING]${NC} SSL certificate expires in ${DAYS_UNTIL_EXPIRY} days"
        ALERTS="${ALERTS}\n- SSL certificate expires in ${DAYS_UNTIL_EXPIRY} days"
    else
        echo -e "${GREEN}[OK]${NC} SSL certificate is valid for ${DAYS_UNTIL_EXPIRY} days"
    fi
fi

# Send alerts if any
if [ -n "${ALERTS}" ]; then
    echo ""
    echo -e "${RED}=== ALERTS DETECTED ===${NC}"
    echo -e "${ALERTS}"

    # Send email alert
    if command -v mail &> /dev/null; then
        echo -e "Server: ${HOSTNAME}\nTime: ${TIMESTAMP}\n\nAlerts:${ALERTS}" | \
            mail -s "FinNaslain System Alert - ${HOSTNAME}" "${ALERT_EMAIL}"
    fi
else
    echo ""
    echo -e "${GREEN}=== All checks passed ===${NC}"
fi

echo ""
echo "=== Health Check Complete ==="
