output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = digitalocean_vpc.main.ip_range
}

output "app_server_ips" {
  description = "Public IP addresses of application servers"
  value       = digitalocean_droplet.app_server[*].ipv4_address
}

output "app_server_private_ips" {
  description = "Private IP addresses of application servers"
  value       = digitalocean_droplet.app_server[*].ipv4_address_private
}

output "load_balancer_ip" {
  description = "Load balancer public IP"
  value       = digitalocean_loadbalancer.app_lb.ip
}

output "database_host" {
  description = "Database host (private)"
  value       = digitalocean_database_cluster.main.private_host
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = digitalocean_database_cluster.main.port
}

output "database_name" {
  description = "Database name"
  value       = digitalocean_database_db.main.name
}

output "database_user" {
  description = "Database user"
  value       = digitalocean_database_user.app_user.name
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = digitalocean_database_user.app_user.password
  sensitive   = true
}

output "database_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.main.private_host}:${digitalocean_database_cluster.main.port}/${digitalocean_database_db.main.name}?sslmode=require"
  sensitive   = true
}

output "database_replica_host" {
  description = "Database replica host (for read operations)"
  value       = var.environment == "production" ? digitalocean_database_replica.read_replica[0].private_host : "N/A"
  sensitive   = true
}

output "project_id" {
  description = "DigitalOcean project ID"
  value       = digitalocean_project.finnaslaim.id
}

output "domain_name" {
  description = "Domain name (if configured)"
  value       = var.domain_name != "" ? var.domain_name : "Not configured"
}

output "application_url" {
  description = "Application URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${digitalocean_loadbalancer.app_lb.ip}"
}
