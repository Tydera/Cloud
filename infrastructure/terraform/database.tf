# Managed PostgreSQL Database Cluster
resource "digitalocean_database_cluster" "main" {
  name       = "${var.project_name}-db-${var.environment}"
  engine     = var.db_engine
  version    = var.db_version
  size       = var.db_size
  region     = var.region
  node_count = var.environment == "production" ? 2 : 1

  private_network_uuid = digitalocean_vpc.main.id

  tags = ["${var.environment}", "database", var.project_name]

  maintenance_window {
    day  = "sunday"
    hour = "02:00:00"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Database for the application
resource "digitalocean_database_db" "main" {
  cluster_id = digitalocean_database_cluster.main.id
  name       = "${var.project_name}_${var.environment}"
}

# Database user for the application
resource "digitalocean_database_user" "app_user" {
  cluster_id = digitalocean_database_cluster.main.id
  name       = "${var.project_name}_app_user"
}

# Firewall rules for database
resource "digitalocean_database_firewall" "main" {
  cluster_id = digitalocean_database_cluster.main.id

  # Allow connections from VPC
  rule {
    type  = "ip_addr"
    value = var.vpc_cidr
  }

  # Allow connections from app servers
  dynamic "rule" {
    for_each = digitalocean_droplet.app_server
    content {
      type  = "droplet"
      value = rule.value.id
    }
  }
}

# Database replica for read-heavy operations (production only)
resource "digitalocean_database_replica" "read_replica" {
  count      = var.environment == "production" ? 1 : 0
  cluster_id = digitalocean_database_cluster.main.id
  name       = "${var.project_name}-db-replica-${var.environment}"
  size       = var.db_size
  region     = var.region

  tags = ["${var.environment}", "database-replica", var.project_name]
}
