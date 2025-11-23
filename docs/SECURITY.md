# Security Best Practices - FinNaslain Financial Solution

## Overview

This document outlines security best practices, procedures, and guidelines for the FinNaslain Financial Solution. As a financial application, security is paramount.

## Table of Contents

1. [Security Principles](#security-principles)
2. [Infrastructure Security](#infrastructure-security)
3. [Application Security](#application-security)
4. [Data Security](#data-security)
5. [Access Control](#access-control)
6. [Monitoring & Incident Response](#monitoring--incident-response)
7. [Compliance](#compliance)
8. [Security Checklist](#security-checklist)

## Security Principles

### Defense in Depth

Multiple layers of security controls:
- Network layer (firewall, VPC)
- Host layer (OS hardening)
- Application layer (input validation, authentication)
- Data layer (encryption)

### Principle of Least Privilege

- Users have minimum necessary permissions
- Service accounts have restricted access
- Time-limited access when possible

### Security by Default

- Secure defaults in all configurations
- Explicit allow rather than explicit deny
- Fail securely (fail closed)

## Infrastructure Security

### Network Security

#### Firewall Configuration

**Required Rules**:
```bash
# Allow SSH from trusted IPs only
ufw allow from TRUSTED_IP to any port 22

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Default deny
ufw default deny incoming
ufw default allow outgoing
```

**Database Access**:
- Only accessible from VPC
- No public internet access
- Connection string uses SSL

**Security Groups**:
```hcl
# Application servers
- SSH: Restricted IPs
- HTTP/HTTPS: All (through load balancer)
- Internal: VPC only

# Database
- PostgreSQL: VPC only
- No public access
```

### Server Hardening

#### SSH Configuration

**/etc/ssh/sshd_config**:
```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
AllowUsers finnaslaim
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

#### Automatic Updates

```bash
# Enable unattended upgrades
apt-get install unattended-upgrades

# Configure auto-updates
dpkg-reconfigure --priority=low unattended-upgrades
```

#### Fail2ban Configuration

**/etc/fail2ban/jail.local**:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
maxretry = 3
bantime = 7200

[nginx-limit-req]
enabled = true
maxretry = 10
```

### Container Security

#### Dockerfile Best Practices

```dockerfile
# Use official base images
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Use non-root user
USER nodejs

# Don't expose unnecessary ports
EXPOSE 8080

# Health checks
HEALTHCHECK CMD node healthcheck.js
```

#### Docker Compose Security

```yaml
services:
  app:
    # No privileged mode
    privileged: false

    # Read-only root filesystem (where possible)
    read_only: true

    # Drop capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

## Application Security

### Authentication

#### JWT Implementation

```javascript
// Strong secret key (256-bit minimum)
JWT_SECRET = crypto.randomBytes(32).toString('hex');

// Token configuration
{
  algorithm: 'HS256',
  expiresIn: '15m',  // Short-lived
  issuer: 'finnaslaim',
  audience: 'finnaslaim-api'
}

// Refresh token
{
  expiresIn: '7d',
  httpOnly: true,
  secure: true,
  sameSite: 'strict'
}
```

#### Password Security

```javascript
// Use bcrypt with proper cost factor
const saltRounds = 12;
const hash = await bcrypt.hash(password, saltRounds);

// Password requirements
{
  minLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true
}
```

#### Multi-Factor Authentication

```javascript
// Implement TOTP (Time-based One-Time Password)
const secret = speakeasy.generateSecret();
const token = speakeasy.totp({
  secret: secret.base32,
  encoding: 'base32'
});
```

### Input Validation

#### Request Validation

```javascript
// Use validation library (e.g., Joi, express-validator)
const schema = Joi.object({
  email: Joi.string().email().required(),
  amount: Joi.number().positive().precision(2).max(1000000),
  accountId: Joi.string().uuid().required()
});

// Validate before processing
const { error, value } = schema.validate(req.body);
if (error) {
  return res.status(400).json({ error: error.details[0].message });
}
```

#### SQL Injection Prevention

```javascript
// ALWAYS use parameterized queries
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// NEVER concatenate user input
// BAD: `SELECT * FROM users WHERE email = '${email}'`
```

#### XSS Prevention

```javascript
// Sanitize output
const sanitizeHtml = require('sanitize-html');
const clean = sanitizeHtml(userInput, {
  allowedTags: [],
  allowedAttributes: {}
});

// Set security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    }
  }
}));
```

### API Security

#### Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});

// Authentication endpoint (stricter)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true
});

app.use('/api/', apiLimiter);
app.use('/api/auth/', authLimiter);
```

#### CORS Configuration

```javascript
const cors = require('cors');

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS.split(','),
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 600 // 10 minutes
}));
```

#### Security Headers

```javascript
app.use(helmet());

// Additional headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Referrer-Policy', 'no-referrer');
  next();
});
```

## Data Security

### Encryption at Rest

#### Database Encryption

```bash
# DigitalOcean Managed Database includes encryption at rest
# Enabled by default

# Verify SSL connection
psql "sslmode=require host=db-host dbname=dbname user=user"
```

#### Application-Level Encryption

```javascript
const crypto = require('crypto');

// Encrypt sensitive fields
function encrypt(text, key) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex')
  };
}

// Decrypt sensitive fields
function decrypt(data, key) {
  const decipher = crypto.createDecipheriv(
    'aes-256-gcm',
    key,
    Buffer.from(data.iv, 'hex')
  );

  decipher.setAuthTag(Buffer.from(data.authTag, 'hex'));

  let decrypted = decipher.update(data.encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}
```

### Encryption in Transit

#### SSL/TLS Configuration

**Nginx Configuration**:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

#### Database Connections

```javascript
// PostgreSQL SSL connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-certificate.crt').toString()
  }
});
```

### Secrets Management

#### Environment Variables

```bash
# NEVER commit .env files
echo ".env" >> .gitignore

# Use strong secrets
JWT_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
```

#### Secrets in CI/CD

```yaml
# GitHub Actions - use secrets
env:
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

#### Secrets in Production

```bash
# Set environment variables on server
echo "export DB_PASSWORD='secret'" >> /etc/environment

# Or use docker secrets
docker secret create db_password db_password.txt
```

## Access Control

### Role-Based Access Control (RBAC)

```javascript
const roles = {
  user: ['read:own', 'write:own'],
  accountant: ['read:all', 'write:own', 'export:reports'],
  admin: ['read:all', 'write:all', 'delete:all', 'manage:users']
};

function authorize(requiredPermission) {
  return (req, res, next) => {
    const userRole = req.user.role;
    const permissions = roles[userRole] || [];

    if (permissions.includes(requiredPermission)) {
      next();
    } else {
      res.status(403).json({ error: 'Forbidden' });
    }
  };
}

// Usage
app.get('/api/users', authorize('read:all'), getUsers);
```

### SSH Access

```bash
# Create separate SSH keys for each team member
ssh-keygen -t ed25519 -C "john@finnaslaim.com"

# Add to DigitalOcean droplet
doctl compute ssh-key create john-key --public-key "$(cat ~/.ssh/id_ed25519.pub)"

# Revoke access by removing key
doctl compute ssh-key delete KEY_ID
```

### Database Access

```sql
-- Create role with limited permissions
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE finnaslaim TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Read-only role for analytics
CREATE ROLE analyst WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE finnaslaim TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst;
```

## Monitoring & Incident Response

### Security Monitoring

#### Log What Matters

```javascript
// Authentication events
logger.info('Login attempt', {
  email: req.body.email,
  ip: req.ip,
  userAgent: req.get('user-agent'),
  success: true
});

// Authorization failures
logger.warn('Unauthorized access attempt', {
  userId: req.user.id,
  resource: req.path,
  action: req.method
});

// Security events
logger.error('Potential security threat', {
  type: 'SQL_INJECTION',
  input: sanitizedInput,
  ip: req.ip
});
```

#### Alerting

```bash
# Monitor failed login attempts
grep "Failed password" /var/log/auth.log | tail -20

# Alert on multiple failures
FAILED_COUNT=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ $FAILED_COUNT -gt 10 ]; then
  mail -s "Security Alert: Multiple Failed Logins" admin@finnaslaim.com
fi
```

### Incident Response Plan

#### 1. Detection
- Automated alerts
- Log monitoring
- User reports

#### 2. Containment
```bash
# Block suspicious IP
ufw deny from SUSPICIOUS_IP

# Disable compromised account
UPDATE users SET is_active = false WHERE email = 'compromised@email.com';

# Rotate credentials
# Update JWT_SECRET, DB_PASSWORD, etc.
```

#### 3. Eradication
- Identify vulnerability
- Apply patches
- Remove malicious code

#### 4. Recovery
- Restore from backup if needed
- Re-enable services
- Monitor closely

#### 5. Post-Incident
- Document incident
- Update procedures
- Implement preventive measures

### Security Audit

```bash
# Run security audit script
sudo bash /usr/local/bin/security-audit.sh

# Check for vulnerable packages
npm audit

# Scan for malware
sudo rkhunter --check

# Review user accounts
cat /etc/passwd | grep -v "nologin"

# Check for unusual processes
ps aux | sort -k3 -r | head -10

# Review firewall rules
sudo ufw status verbose

# Check listening ports
sudo netstat -tlnp
```

## Compliance

### Data Protection (GDPR, CCPA)

#### User Rights

```javascript
// Right to access
app.get('/api/users/me/data', authenticate, async (req, res) => {
  const userData = await getUserData(req.user.id);
  res.json(userData);
});

// Right to deletion
app.delete('/api/users/me', authenticate, async (req, res) => {
  await deleteUser(req.user.id);
  res.status(204).send();
});

// Right to data portability
app.get('/api/users/me/export', authenticate, async (req, res) => {
  const data = await exportUserData(req.user.id);
  res.attachment('user-data.json').send(data);
});
```

#### Data Retention

```javascript
// Automatically delete old audit logs
cron.schedule('0 0 * * *', async () => {
  const retentionDays = 2555; // 7 years
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

  await db.query(
    'DELETE FROM audit_logs WHERE created_at < $1',
    [cutoffDate]
  );
});
```

### Audit Logging

```javascript
// Log all sensitive operations
function auditLog(userId, action, entityType, entityId, details) {
  return db.query(
    `INSERT INTO audit_logs
     (user_id, action, entity_type, entity_id, ip_address, user_agent, details, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
    [userId, action, entityType, entityId, req.ip, req.get('user-agent'), details]
  );
}

// Usage
await auditLog(
  req.user.id,
  'TRANSACTION_CREATE',
  'transaction',
  transaction.id,
  { amount: transaction.amount, type: transaction.type }
);
```

## Security Checklist

### Infrastructure

- [ ] Firewall configured with restrictive rules
- [ ] SSH key-only authentication enabled
- [ ] Fail2ban configured and running
- [ ] Automatic security updates enabled
- [ ] VPC configured with private networking
- [ ] Database not publicly accessible
- [ ] SSL/TLS certificates installed and auto-renewing
- [ ] Backups encrypted and tested
- [ ] Monitoring and alerting configured
- [ ] Security audit script scheduled

### Application

- [ ] All dependencies up to date
- [ ] No known vulnerabilities (npm audit)
- [ ] Input validation on all endpoints
- [ ] Output encoding to prevent XSS
- [ ] Parameterized queries (no SQL injection)
- [ ] CSRF protection enabled
- [ ] Rate limiting configured
- [ ] Security headers set
- [ ] CORS properly configured
- [ ] Secrets not in code or version control
- [ ] Error messages don't leak sensitive info
- [ ] Audit logging implemented

### Authentication & Authorization

- [ ] Strong password policy enforced
- [ ] Passwords hashed with bcrypt (cost >= 10)
- [ ] JWT tokens expire appropriately
- [ ] Refresh tokens implemented
- [ ] MFA available for sensitive accounts
- [ ] Account lockout after failed attempts
- [ ] Role-based access control implemented
- [ ] Principle of least privilege applied
- [ ] Session management secure

### Data Protection

- [ ] Encryption at rest enabled
- [ ] Encryption in transit enforced (TLS 1.2+)
- [ ] Sensitive data encrypted in application
- [ ] PII identified and protected
- [ ] Data retention policy implemented
- [ ] Backup encryption enabled
- [ ] GDPR compliance measures in place

### Monitoring & Response

- [ ] Security events logged
- [ ] Logs protected from tampering
- [ ] Automated alerts configured
- [ ] Incident response plan documented
- [ ] Security contact information up to date
- [ ] Regular security audits scheduled
- [ ] Vulnerability disclosure policy published

## Resources

### Tools

- **OWASP ZAP**: Web application security scanner
- **Nmap**: Network security scanner
- **Nikto**: Web server scanner
- **Lynis**: Security auditing tool
- **Snyk**: Dependency vulnerability scanner

### References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [DigitalOcean Security](https://www.digitalocean.com/docs/security/)

## Contact

For security concerns or to report vulnerabilities:
- Email: security@finnaslaim.com
- PGP Key: [Link to PGP key]

**Please do not disclose security vulnerabilities publicly until they have been addressed.**

---

**Document Version:** 1.0
**Last Updated:** 2024-01-01
**Author:** Security Team
