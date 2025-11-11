# Main configuration file for FinNaslain Financial Solution on DigitalOcean

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = "FinNaslain-Financial-Solution"
  }
}

# Create a DigitalOcean project
resource "digitalocean_project" "finnaslaim" {
  name        = "${var.project_name}-${var.environment}"
  description = "FinNaslain Financial Solution - ${var.environment} environment"
  purpose     = "Financial Services"
  environment = var.environment
}

# SSH Key for accessing droplets
resource "digitalocean_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

# Data source for existing SSH keys (if any)
data "digitalocean_ssh_keys" "existing" {
  sort {
    key       = "name"
    direction = "asc"
  }
}
