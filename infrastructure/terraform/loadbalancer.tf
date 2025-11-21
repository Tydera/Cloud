# Load Balancer for application servers
resource "digitalocean_loadbalancer" "app_lb" {
  name   = "${var.project_name}-lb-${var.environment}"
  region = var.region

  vpc_uuid = digitalocean_vpc.main.id

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_name = var.domain_name != "" ? digitalocean_certificate.cert[0].name : ""
  }

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    unhealthy_threshold      = 3
    healthy_threshold        = 3
  }

  droplet_ids = digitalocean_droplet.app_server[*].id

  redirect_http_to_https = var.domain_name != "" ? true : false

  enable_proxy_protocol = false
  enable_backend_keepalive = true

  lifecycle {
    create_before_destroy = true
  }
}

# SSL Certificate (if domain is provided)
resource "digitalocean_certificate" "cert" {
  count = var.domain_name != "" ? 1 : 0

  name    = "${var.project_name}-cert-${var.environment}"
  type    = "lets_encrypt"
  domains = [var.domain_name, "www.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

# Domain records (if domain is provided)
resource "digitalocean_domain" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

resource "digitalocean_record" "apex" {
  count = var.domain_name != "" ? 1 : 0

  domain = digitalocean_domain.main[0].id
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.app_lb.ip
  ttl    = 300
}

resource "digitalocean_record" "www" {
  count = var.domain_name != "" ? 1 : 0

  domain = digitalocean_domain.main[0].id
  type   = "CNAME"
  name   = "www"
  value  = "${var.domain_name}."
  ttl    = 300
}
