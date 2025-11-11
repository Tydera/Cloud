variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "finnaslaim"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "app_droplet_size" {
  description = "Size of application droplets"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "app_droplet_count" {
  description = "Number of application droplets"
  type        = number
  default     = 2
}

variable "db_size" {
  description = "Size of managed database"
  type        = string
  default     = "db-s-2vcpu-4gb"
}

variable "db_engine" {
  description = "Database engine (pg, mysql, redis)"
  type        = string
  default     = "pg"
}

variable "db_version" {
  description = "Database version"
  type        = string
  default     = "15"
}

variable "ssh_key_name" {
  description = "Name of SSH key for droplets"
  type        = string
  default     = "finnaslaim-ssh-key"
}

variable "alert_email" {
  description = "Email for monitoring alerts"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable monitoring on droplets"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable backups on droplets"
  type        = bool
  default     = true
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "finnaslaim/app:latest"
}
