
resource "google_compute_region_network_endpoint_group" "serverless_negs" {
  for_each = var.mapping_services

  name                  = "${var.name}-${each.value.name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project              = var.project
  cloud_run {
    service = each.value.service_name
  }
}

resource "google_compute_backend_service" "backend_services" {
  for_each = google_compute_region_network_endpoint_group.serverless_negs
  project = var.project
  name                  = "${var.name}-${each.key}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"

  backend {
    group = each.value.id
  }
}

resource "google_compute_health_check" "default" {
  name = "${var.name}-default-health-check"
  project = var.project
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_compute_url_map" "url_map" {
  name = "${var.name}-url-map"
  project = var.project
  host_rule {
    hosts        = [var.domain]
    path_matcher = "${var.name}-path-rules"
  }

  default_service = google_compute_backend_service.backend_services[keys(var.mapping_services)[0]].id

  path_matcher {
    name = "${var.name}-path-rules"
    default_service = google_compute_backend_service.backend_services[keys(var.mapping_services)[0]].id

    dynamic "path_rule" {
      for_each = var.mapping_services
      content {
        paths   = [path_rule.value.path]
        service = google_compute_backend_service.backend_services[path_rule.key].id
        route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }
  }
}
}

resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.project
  name    = "${var.name}-http-lb-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  project = var.project
  name                  = "${var.name}-http-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "${var.name}lb-ssl-cert"
  project=var.project
  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project = var.project
  name             = "${var.name}-https-lb-proxy"
  url_map         = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  project = var.project
  name                  = "${var.name}-https-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
}
