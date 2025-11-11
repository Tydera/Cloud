# FinNaslain Financial Solution - DigitalOcean Infrastructure

A comprehensive cloud infrastructure setup for the FinNaslain Financial Solution, deployed on DigitalOcean with security best practices, automated CI/CD, and high availability.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Components](#infrastructure-components)
- [Deployment](#deployment)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup & Recovery](#backup--recovery)
- [Development](#development)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains the complete infrastructure-as-code setup for the FinNaslain Financial Solution, including:

- **Infrastructure as Code**: Terraform configurations for DigitalOcean
- **Containerization**: Docker and Docker Compose setups
- **CI/CD**: GitHub Actions workflows
- **Security**: Hardened configurations and security scripts
- **Monitoring**: Health checks and alerting
- **Backup**: Automated backup solutions

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      DigitalOcean Cloud                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐         ┌─────────────────────┐             │
│  │ Load Balancer│────────▶│   Application VPC   │             │
│  │   (SSL/TLS)  │         │   (10.10.0.0/16)    │             │
│  └──────────────┘         └─────────────────────┘             │
│         │                           │                           │
│         │                  ┌────────┴────────┐                 │
│         │                  │                 │                 │
│         │          ┌───────▼──────┐  ┌──────▼───────┐         │
│         └─────────▶│  App Server  │  │ App Server   │         │
│                    │  (Droplet 1) │  │ (Droplet 2)  │         │
│                    └───────┬──────┘  └──────┬───────┘         │
│                            │                │                  │
│                            └────────┬───────┘                  │
│                                     │                          │
│                            ┌────────▼────────┐                 │
│                            │   PostgreSQL    │                 │
│                            │  (Managed DB)   │                 │
│                            │  w/ Replica     │                 │
│                            └─────────────────┘                 │
│                                                                  │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐         │
│  │   Redis     │   │   Spaces    │   │  Firewall   │         │
│  │  (Cache)    │   │  (Storage)  │   │   Rules     │         │
│  └─────────────┘   └─────────────┘   └─────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [Docker](https://docs.docker.com/get-docker/) >= 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.0
- [Node.js](https://nodejs.org/) >= 18.x
- [Git](https://git-scm.com/)
- [DigitalOcean Account](https://cloud.digitalocean.com/)

### DigitalOcean Setup

1. Create a DigitalOcean account
2. Generate a Personal Access Token (Settings → API → Tokens)
3. Create a Spaces bucket for Terraform state
4. Generate Spaces access keys

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Tydera/Cloud.git
cd Cloud
```

### 2. Configure Environment Variables

```bash
cp config/.env.example .env
# Edit .env with your configuration
```

### 3. Initialize Terraform

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### 4. Deploy Application

```bash
# Using make
make deploy

# Or manually
sudo bash infrastructure/scripts/deploy.sh
```

## Infrastructure Components

### VPC and Networking

- **VPC**: Isolated private network (10.10.0.0/16)
- **Firewall**: Configured rules for SSH, HTTP, HTTPS
- **Load Balancer**: SSL termination and traffic distribution

### Compute

- **Droplets**: Ubuntu 22.04 LTS
- **Size**: s-2vcpu-4gb (configurable)
- **Count**: 2 (configurable for high availability)

### Database

- **Engine**: PostgreSQL 15
- **Configuration**: Managed database with automated backups
- **Replica**: Read replica for production environment

### Storage

- **Spaces**: Object storage for backups and static assets
- **Volumes**: Persistent storage for application data

## Deployment

### Manual Deployment

```bash
# SSH into droplet
ssh root@your-droplet-ip

# Run deployment script
sudo bash /opt/finnaslaim/deploy.sh
```

### Automated Deployment

Deployments are automatically triggered on push to `main` branch via GitHub Actions.

```bash
git add .
git commit -m "Your changes"
git push origin main
```

## Security

### Security Features

- ✅ Firewall (UFW) configured
- ✅ Fail2ban for intrusion prevention
- ✅ Automatic security updates
- ✅ SSH hardening (key-only authentication)
- ✅ SSL/TLS encryption
- ✅ Database connection encryption
- ✅ Secrets management
- ✅ Security scanning in CI/CD

### Run Security Audit

```bash
make security-audit
# Or
sudo bash /usr/local/bin/security-audit.sh
```

### Setup Security Hardening

```bash
sudo bash infrastructure/scripts/setup-security.sh
```

## Monitoring

### Health Checks

The application exposes a `/health` endpoint for monitoring.

```bash
curl http://your-domain/health
```

### Run Monitoring Check

```bash
make monitoring
# Or
sudo bash infrastructure/scripts/monitoring.sh
```

### Monitoring Features

- CPU usage monitoring
- Memory usage monitoring
- Disk usage monitoring
- Docker container health
- Database connectivity
- Application health endpoints
- SSL certificate expiration

## Backup & Recovery

### Automated Backups

Backups run automatically via cron jobs.

```bash
# Manual backup
make backup
# Or
sudo bash infrastructure/scripts/backup.sh
```

### Backup Contents

- PostgreSQL database dumps
- Application files
- Configuration files
- Uploaded to DigitalOcean Spaces

### Restore from Backup

```bash
# Restore database
gunzip -c /var/backups/finnaslaim/db_TIMESTAMP.dump.gz | \
  pg_restore -h DB_HOST -U DB_USER -d DB_NAME

# Restore application files
tar -xzf /var/backups/finnaslaim/app_TIMESTAMP.tar.gz -C /opt/finnaslaim
```

## Development

### Local Development Setup

```bash
# Install dependencies
make install

# Start development environment
make dev
```

### Development Environment Includes

- PostgreSQL database
- Redis cache
- pgAdmin (http://localhost:5050)
- Hot-reload enabled
- Debug port (9229)

### Available Commands

```bash
make help              # Show all available commands
make install           # Install dependencies
make dev              # Start development environment
make test             # Run tests
make lint             # Run linter
make format           # Format code
make docker-build     # Build Docker image
make terraform-plan   # Plan infrastructure changes
```

## CI/CD Pipeline

### GitHub Actions Workflows

1. **CI Pipeline** (`.github/workflows/ci.yml`)
   - Linting
   - Unit tests
   - Integration tests
   - Security scanning
   - Build verification

2. **CD Pipeline** (`.github/workflows/cd.yml`)
   - Docker image build and push
   - Deployment to DigitalOcean
   - Health checks
   - Rollback on failure

3. **Terraform Pipeline** (`.github/workflows/terraform.yml`)
   - Infrastructure validation
   - Plan on PR
   - Apply on merge to main

4. **Security Scanning** (`.github/workflows/security-scan.yml`)
   - Dependency scanning
   - Code security analysis
   - Docker image scanning
   - Terraform security checks

### Required Secrets

Configure these in GitHub repository settings:

- `DIGITALOCEAN_ACCESS_TOKEN`
- `DIGITALOCEAN_SSH_KEY`
- `DO_SPACES_ACCESS_KEY`
- `DO_SPACES_SECRET_KEY`
- `DROPLET_IPS`
- `ALERT_EMAIL`
- `SLACK_WEBHOOK` (optional)
- `SNYK_TOKEN` (optional)

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock

```bash
cd infrastructure/terraform
terraform force-unlock LOCK_ID
```

#### 2. Docker Container Not Starting

```bash
docker logs finnaslaim-app
docker-compose down && docker-compose up -d
```

#### 3. Database Connection Issues

```bash
# Check database status
docker exec -it finnaslaim-postgres-dev pg_isready

# Check connection string
echo $DATABASE_URL
```

#### 4. High Resource Usage

```bash
# Check resource usage
make monitoring

# Scale down if needed
docker-compose down
docker-compose up -d --scale app=1
```

### Logs

```bash
# Application logs
docker logs finnaslaim-app -f

# Nginx logs
docker logs finnaslaim-nginx -f

# System logs
tail -f /var/log/syslog
```

## Project Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD pipelines
├── config/                 # Configuration files
│   ├── .env.example
│   ├── database.config.js
│   └── redis.config.js
├── docker/
│   ├── production/         # Production Docker configs
│   └── development/        # Development Docker configs
├── docs/                   # Additional documentation
├── infrastructure/
│   ├── terraform/          # Terraform IaC files
│   └── scripts/           # Deployment and maintenance scripts
├── .dockerignore
├── .editorconfig
├── .eslintrc.json
├── .gitignore
├── .prettierrc.json
├── Makefile              # Build automation
└── README.md             # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Copyright © 2024 FinNaslain. All rights reserved.

## Support

For support, email admin@finnaslaim.com or create an issue in this repository.

---

**Built with ❤️ for secure, scalable financial solutions**
