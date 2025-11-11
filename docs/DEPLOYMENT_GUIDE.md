# FinNaslain Deployment Guide

This guide provides step-by-step instructions for deploying the FinNaslain Financial Solution to DigitalOcean.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Initial Infrastructure Setup](#initial-infrastructure-setup)
3. [Application Deployment](#application-deployment)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Domain Configuration](#domain-configuration)
6. [SSL/TLS Setup](#ssltls-setup)
7. [Monitoring Setup](#monitoring-setup)
8. [Backup Configuration](#backup-configuration)
9. [Rollback Procedures](#rollback-procedures)

## Pre-Deployment Checklist

### Required Information

- [ ] DigitalOcean Personal Access Token
- [ ] DigitalOcean Spaces credentials
- [ ] SSH public key
- [ ] Domain name (optional)
- [ ] Alert email address
- [ ] SMTP credentials (for notifications)

### Required Tools Installed

- [ ] Terraform >= 1.5.0
- [ ] Docker >= 20.10
- [ ] Git
- [ ] SSH client
- [ ] doctl (DigitalOcean CLI) - optional

## Initial Infrastructure Setup

### Step 1: Configure DigitalOcean Account

1. **Create DigitalOcean Account**
   - Sign up at https://cloud.digitalocean.com
   - Verify your email and add billing information

2. **Generate Personal Access Token**
   ```
   Dashboard → API → Tokens/Keys → Generate New Token
   Name: finnaslaim-terraform
   Scopes: Read and Write
   ```
   Save this token securely.

3. **Create Spaces Bucket**
   ```
   Dashboard → Spaces → Create Space
   Datacenter: NYC3
   Name: finnaslaim-terraform-state
   Enable CDN: No (optional)
   ```

4. **Generate Spaces Keys**
   ```
   Dashboard → API → Spaces Keys → Generate New Key
   Name: finnaslaim-spaces
   ```
   Save Access Key ID and Secret Key.

### Step 2: Clone and Configure Repository

```bash
# Clone repository
git clone https://github.com/Tydera/Cloud.git
cd Cloud

# Create SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -C "finnaslaim@deployment"

# Add SSH key to DigitalOcean
# Dashboard → Settings → Security → SSH Keys → Add SSH Key
```

### Step 3: Configure Terraform Variables

```bash
cd infrastructure/terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
nano terraform.tfvars
```

Update with your values:

```hcl
do_token         = "your-digitalocean-token"
project_name     = "finnaslaim"
environment      = "production"
region           = "nyc3"
alert_email      = "admin@finnaslaim.com"
domain_name      = "finnaslaim.com"  # Optional
ssh_key_name     = "finnaslaim-ssh-key"
app_droplet_count = 2
enable_monitoring = true
enable_backups    = true
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review plan
terraform plan

# Apply configuration (creates infrastructure)
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:
application_url = "http://159.89.123.456"
load_balancer_ip = "159.89.123.456"
app_server_ips = ["159.89.123.100", "159.89.123.101"]
database_host = "private-db-host.db.ondigitalocean.com"
```

**Save these outputs!** You'll need them for the next steps.

### Step 5: Configure DNS (If Using Domain)

If you specified a domain name, configure your DNS:

1. **At Your Domain Registrar:**
   - Update nameservers to DigitalOcean:
     - ns1.digitalocean.com
     - ns2.digitalocean.com
     - ns3.digitalocean.com

2. **Wait for DNS Propagation** (can take up to 48 hours)

3. **Verify DNS:**
   ```bash
   dig finnaslaim.com
   ```

## Application Deployment

### Step 1: Configure Environment Variables

```bash
# On your local machine
cd Cloud
cp config/.env.example .env

# Edit .env with production values
nano .env
```

Update critical values:

```env
NODE_ENV=production
DB_HOST=<from terraform output>
DB_PORT=5432
DB_NAME=<from terraform output>
DB_USER=<from terraform output>
DB_PASSWORD=<from terraform output>
JWT_SECRET=<generate-secure-random-string>
ENCRYPTION_KEY=<generate-32-character-key>
```

### Step 2: Build and Push Docker Image

#### Option A: Using GitHub Actions (Recommended)

```bash
# Commit and push to trigger CI/CD
git add .
git commit -m "Initial deployment configuration"
git push origin main
```

GitHub Actions will automatically:
1. Build the Docker image
2. Push to GitHub Container Registry
3. Deploy to DigitalOcean droplets

#### Option B: Manual Build and Deploy

```bash
# Build Docker image
docker build -f docker/production/Dockerfile -t finnaslaim/app:latest .

# Tag for registry
docker tag finnaslaim/app:latest ghcr.io/tydera/cloud:latest

# Push to registry
docker login ghcr.io
docker push ghcr.io/tydera/cloud:latest

# SSH to droplets and deploy
APP_SERVER_IP=<from terraform output>
ssh root@$APP_SERVER_IP

# On the droplet
cd /opt/finnaslaim
docker-compose pull
docker-compose up -d
```

### Step 3: Initialize Database

```bash
# SSH to first app server
ssh root@<app-server-ip>

# Run database migrations
docker exec -it finnaslaim-app npm run db:migrate

# (Optional) Seed initial data
docker exec -it finnaslaim-app npm run db:seed
```

### Step 4: Configure Security

```bash
# Run security setup script on each droplet
ssh root@<app-server-ip>
bash /opt/finnaslaim/infrastructure/scripts/setup-security.sh
```

## Post-Deployment Verification

### Step 1: Health Checks

```bash
# Check application health
curl http://<load-balancer-ip>/health

# Expected response:
# {"status":"ok","timestamp":"2024-01-01T12:00:00Z"}
```

### Step 2: Verify Services

```bash
# SSH to app server
ssh root@<app-server-ip>

# Check Docker containers
docker ps

# Should show:
# - finnaslaim-app
# - finnaslaim-redis
# - finnaslaim-nginx (if using)

# Check logs
docker logs finnaslaim-app --tail 50
```

### Step 3: Test Application Endpoints

```bash
# Test API endpoints
curl http://<load-balancer-ip>/api/v1/health
curl http://<load-balancer-ip>/api/v1/status
```

### Step 4: Verify Database Connection

```bash
# Connect to database
docker exec -it finnaslaim-app node -e "require('./config/database').testConnection()"
```

### Step 5: Run Monitoring Check

```bash
ssh root@<app-server-ip>
bash /opt/finnaslaim/infrastructure/scripts/monitoring.sh
```

## Domain Configuration

### Step 1: Verify DNS Records

```bash
# Check A record
dig finnaslaim.com A

# Check CNAME record
dig www.finnaslaim.com CNAME
```

### Step 2: SSL Certificate

Terraform automatically provisions Let's Encrypt certificates if domain is configured.

**Verify SSL:**
```bash
curl https://finnaslaim.com/health
```

**Check certificate expiration:**
```bash
echo | openssl s_client -connect finnaslaim.com:443 2>/dev/null | openssl x509 -noout -dates
```

## SSL/TLS Setup

### Manual SSL Setup (If Not Using Terraform)

```bash
# Install certbot on droplet
ssh root@<app-server-ip>
apt-get install certbot python3-certbot-nginx

# Obtain certificate
certbot --nginx -d finnaslaim.com -d www.finnaslaim.com

# Test renewal
certbot renew --dry-run

# Auto-renewal is configured via cron
```

## Monitoring Setup

### Step 1: Configure Alerts

Edit monitoring script to set thresholds:

```bash
ssh root@<app-server-ip>
nano /opt/finnaslaim/infrastructure/scripts/monitoring.sh

# Adjust thresholds:
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=85
```

### Step 2: Schedule Monitoring

```bash
# Add to crontab
crontab -e

# Add monitoring check every 5 minutes
*/5 * * * * /opt/finnaslaim/infrastructure/scripts/monitoring.sh

# Add daily security audit
0 2 * * * /usr/local/bin/security-audit.sh | mail -s "Security Audit" admin@finnaslaim.com
```

### Step 3: Configure External Monitoring (Optional)

Consider setting up:
- **UptimeRobot** for uptime monitoring
- **Sentry** for error tracking
- **Datadog/New Relic** for APM
- **DigitalOcean Monitoring** (built-in)

## Backup Configuration

### Step 1: Configure Backup Script

```bash
ssh root@<app-server-ip>
nano /opt/finnaslaim/infrastructure/scripts/backup.sh

# Update configuration
BACKUP_DIR="/var/backups/finnaslaim"
RETENTION_DAYS=30
S3_BUCKET="finnaslaim-backups"
```

### Step 2: Schedule Backups

```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /opt/finnaslaim/infrastructure/scripts/backup.sh

# Weekly full backup on Sunday
0 3 * * 0 /opt/finnaslaim/infrastructure/scripts/backup.sh
```

### Step 3: Test Backup

```bash
# Run manual backup
bash /opt/finnaslaim/infrastructure/scripts/backup.sh

# Verify backup files
ls -lh /var/backups/finnaslaim/
```

### Step 4: Test Restore

```bash
# Test database restore
LATEST_BACKUP=$(ls -t /var/backups/finnaslaim/db_*.dump.gz | head -1)
gunzip -c $LATEST_BACKUP | pg_restore --list
```

## Rollback Procedures

### Application Rollback

```bash
# SSH to app server
ssh root@<app-server-ip>

# View deployment backups
ls -lh /var/backups/finnaslaim/deployments/

# Rollback to specific deployment
cd /opt/finnaslaim
docker-compose down
tar -xzf /var/backups/finnaslaim/deployments/deployment_TIMESTAMP.tar.gz -C /opt/finnaslaim
docker-compose up -d

# Verify rollback
curl http://localhost/health
```

### Database Rollback

```bash
# Stop application
docker-compose down

# Restore database
BACKUP_FILE="/var/backups/finnaslaim/db_TIMESTAMP.dump.gz"
gunzip -c $BACKUP_FILE | pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -c

# Start application
docker-compose up -d
```

### Infrastructure Rollback

```bash
cd infrastructure/terraform

# View previous states
terraform state list

# Revert to previous state
terraform apply -target=specific_resource
```

## Troubleshooting Common Issues

### Issue 1: Application Won't Start

```bash
# Check logs
docker logs finnaslaim-app

# Check environment variables
docker exec finnaslaim-app env

# Restart containers
docker-compose restart
```

### Issue 2: Database Connection Failed

```bash
# Check database status
docker exec finnaslaim-postgres pg_isready

# Test connection
psql -h $DB_HOST -U $DB_USER -d $DB_NAME

# Check firewall
ufw status
```

### Issue 3: High Resource Usage

```bash
# Check resource usage
htop
docker stats

# Scale down if needed
docker-compose down
docker-compose up -d --scale app=1
```

### Issue 4: SSL Certificate Issues

```bash
# Renew certificate
certbot renew --force-renewal

# Check nginx configuration
nginx -t
systemctl restart nginx
```

## Next Steps

After successful deployment:

1. [ ] Set up monitoring alerts
2. [ ] Configure backup verification
3. [ ] Set up log aggregation
4. [ ] Configure CDN (if needed)
5. [ ] Set up staging environment
6. [ ] Document runbooks
7. [ ] Train team on deployment procedures

## Support

For deployment issues:
- Email: admin@finnaslaim.com
- Documentation: https://github.com/Tydera/Cloud/docs
- DigitalOcean Support: https://www.digitalocean.com/support

---

**Document Version:** 1.0
**Last Updated:** 2024-01-01
**Author:** Cloud Engineering Team
