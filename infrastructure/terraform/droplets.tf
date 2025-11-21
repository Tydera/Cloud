# Application servers
resource "digitalocean_droplet" "app_server" {
  count = var.app_droplet_count

  name   = "${var.project_name}-app-${count.index + 1}-${var.environment}"
  image  = "ubuntu-22-04-x64"
  size   = var.app_droplet_size
  region = var.region

  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys = [digitalocean_ssh_key.default.id]

  monitoring = var.enable_monitoring
  backups    = var.enable_backups

  tags = ["${var.environment}", "app-server", var.project_name]

  user_data = templatefile("${path.module}/scripts/cloud-init.yml", {
    docker_image = var.docker_image
    environment  = var.environment
    db_host      = digitalocean_database_cluster.main.private_host
    db_port      = digitalocean_database_cluster.main.port
    db_name      = digitalocean_database_db.main.name
    db_user      = digitalocean_database_user.app_user.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Reserved IP for load balancer
resource "digitalocean_reserved_ip" "app_lb" {
  region = var.region
}

# Assign project resources
resource "digitalocean_project_resources" "resources" {
  project = digitalocean_project.finnaslaim.id

  resources = concat(
    digitalocean_droplet.app_server[*].urn,
    [digitalocean_database_cluster.main.urn],
    [digitalocean_loadbalancer.app_lb.urn]
  )
}
