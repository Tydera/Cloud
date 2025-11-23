# VPC for secure networking
resource "digitalocean_vpc" "main" {
  name        = "${var.project_name}-vpc-${var.environment}"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = "VPC for ${var.project_name} ${var.environment}"
}

# Firewall for application servers
resource "digitalocean_firewall" "app_firewall" {
  name = "${var.project_name}-app-firewall-${var.environment}"

  droplet_ids = digitalocean_droplet.app_server[*].id

  # Allow SSH from trusted sources
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"] # Restrict this in production
  }

  # Allow HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow internal VPC communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Firewall for database
resource "digitalocean_firewall" "db_firewall" {
  name = "${var.project_name}-db-firewall-${var.environment}"

  droplet_ids = []

  # Allow database connections only from VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5432"
    source_addresses = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
