#!/bin/bash

###############################################################################
# Security Setup Script for FinNaslain Financial Solution
# This script hardens the DigitalOcean droplet security
###############################################################################

set -e

echo "=== Starting Security Setup ==="

# Update system packages
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install security tools
echo "Installing security tools..."
apt-get install -y \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    logwatch \
    rkhunter \
    lynis

# Configure UFW firewall
echo "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Configure fail2ban
echo "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@finnaslaim.com
sendername = Fail2Ban

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Configure automatic security updates
echo "Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Secure SSH configuration
echo "Securing SSH configuration..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
echo "AllowUsers finnaslaim" >> /etc/ssh/sshd_config
systemctl restart sshd

# Configure system limits
echo "Configuring system limits..."
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Disable unnecessary services
echo "Disabling unnecessary services..."
systemctl disable bluetooth.service || true
systemctl disable cups.service || true

# Set up file integrity monitoring
echo "Setting up file integrity monitoring..."
rkhunter --update
rkhunter --propupd

# Configure kernel parameters
echo "Configuring kernel security parameters..."
cat >> /etc/sysctl.conf <<EOF

# IP forwarding
net.ipv4.ip_forward = 0

# SYN cookies
net.ipv4.tcp_syncookies = 1

# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Log martians
net.ipv4.conf.all.log_martians = 1
EOF

sysctl -p

# Set up log monitoring
echo "Setting up log monitoring..."
cat > /etc/cron.daily/logwatch <<EOF
#!/bin/bash
/usr/sbin/logwatch --output mail --mailto admin@finnaslaim.com --detail high
EOF
chmod +x /etc/cron.daily/logwatch

# Create security audit script
echo "Creating security audit script..."
cat > /usr/local/bin/security-audit.sh <<'EOF'
#!/bin/bash
echo "=== Security Audit Report ==="
echo "Generated: $(date)"
echo ""
echo "=== System Updates ==="
apt list --upgradable
echo ""
echo "=== Failed Login Attempts ==="
grep "Failed password" /var/log/auth.log | tail -20
echo ""
echo "=== Listening Ports ==="
netstat -tlnp
echo ""
echo "=== Firewall Status ==="
ufw status verbose
echo ""
echo "=== Fail2ban Status ==="
fail2ban-client status
EOF

chmod +x /usr/local/bin/security-audit.sh

# Set file permissions
echo "Setting secure file permissions..."
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group

echo "=== Security Setup Complete ==="
echo "Please review the configuration and adjust as needed."
echo "Run 'security-audit.sh' to generate a security audit report."
