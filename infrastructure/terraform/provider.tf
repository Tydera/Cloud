terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.0"
    }
  }

  # Backend configuration for remote state storage
  backend "s3" {
    # DigitalOcean Spaces configuration
    endpoint                    = "https://nyc3.digitaloceanspaces.com"
    region                      = "us-east-1"
    bucket                      = "finnaslaim-terraform-state"
    key                         = "production/terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "digitalocean" {
  token = var.do_token
}
