resource "google_dns_managed_zone" "managed_zone" {
  name     = var.zone_name
  dns_name = var.dns_name
}

resource "google_dns_record_set" "dev_api" {
  managed_zone = google_dns_managed_zone.managed_zone.name
  name         = "api-.${google_dns_managed_zone.managed_zone.dns_name}"
  rrdatas      = [google_compute_global_address.api_fwd_address.address]
  ttl          = 300
  type         = "A"
}

resource "google_compute_global_network_endpoint_group" "api_neg" {
  name                  = "apigw-neg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
}

resource "google_compute_global_network_endpoint" "api_endpoint" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.api_neg.id
  port                          = 443
  fqdn                          = google_api_gateway_gateway.api_gateway.default_hostname
}

resource "google_compute_backend_service" "api_lb_backend" {
  provider               = google-beta
  name                   = "apigw-lb-backend"
  enable_cdn             = true
  protocol               = "HTTP2"
  custom_request_headers = ["Host: ${google_compute_global_network_endpoint.api_endpoint.fqdn}"]

  backend {
    group = google_compute_global_network_endpoint_group.api_neg.id
  }
}

resource "google_compute_url_map" "api_url_map" {
  name            = "apigw-url-map"
  default_service = google_compute_backend_service.api_lb_backend.id
}

resource "google_compute_managed_ssl_certificate" "api_ssl_cert" {
  name = "apigw-ssl-cert"

  managed {
    domains = ["api.my-domain.com"]
  }
}

resource "google_compute_target_https_proxy" "api_target_proxy" {
  name             = "apigw-target-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.api_ssl_cert.id]
  url_map          = google_compute_url_map.api_url_map.id
}

resource "google_compute_global_address" "api_fwd_address" {
  name = "apigw-fwd-rule-address"
}

resource "google_compute_global_forwarding_rule" "api_fwd_rule" {
  name        = "apigw-fwd-rule"
  target      = google_compute_target_https_proxy.api_target_proxy.id
  ip_protocol = "TCP"
  port_range  = "443"
  ip_address  = google_compute_global_address.api_fwd_address.address
}