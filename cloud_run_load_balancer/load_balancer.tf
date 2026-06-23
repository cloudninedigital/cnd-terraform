locals {
  requested_static_ip = trimspace(var.static_ip_address)
  create_static_ip    = var.use_static_ip && local.requested_static_ip == ""

  secondary_ip_version        = upper(var.ip_version) == "IPV4" ? "IPV6" : "IPV4"
  requested_secondary_static_ip = trimspace(var.secondary_static_ip_address)
  create_secondary_static_ip  = var.enable_dual_stack && var.use_static_ip && local.requested_secondary_static_ip == ""

  all_domains = concat([var.domain], [for k, v in var.host_mappings : v.domain])
}



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

resource "google_compute_region_network_endpoint_group" "host_negs" {
  for_each = var.host_mappings

  name                  = "${var.name}-${each.key}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project
  cloud_run {
    service = each.value.service_name
  }
}

resource "google_compute_backend_service" "host_backends" {
  for_each = google_compute_region_network_endpoint_group.host_negs
  project  = var.project
  name                  = "${var.name}-${each.key}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"

  backend {
    group = each.value.id
  }
}

resource "google_compute_url_map" "url_map" {
  name = "${var.name}-url-map"
  project = var.project
  host_rule {
    hosts        = [var.domain]
    path_matcher = "${var.name}-path-rules"
  }

  dynamic "host_rule" {
    for_each = var.host_mappings
    content {
      hosts        = [host_rule.value.domain]
      path_matcher = "${var.name}-${host_rule.key}-host"
    }
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

  dynamic "path_matcher" {
    for_each = var.host_mappings
    content {
      name            = "${var.name}-${path_matcher.key}-host"
      default_service = google_compute_backend_service.host_backends[path_matcher.key].id
    }
  }
}

resource "google_compute_url_map" "https_redirect" {
  count   = var.enable_https_redirect ? 1 : 0
  name    = "${var.name}-https-redirect"
  project = var.project
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.project
  name    = "${var.name}-http-lb-proxy"
  url_map = var.enable_https_redirect ? google_compute_url_map.https_redirect[0].id : google_compute_url_map.url_map.id
}

resource "google_compute_global_address" "lb_ip" {
  count   = local.create_static_ip ? 1 : 0
  project = var.project
  name    = var.static_ip_name != "" ? var.static_ip_name : "${var.name}-lb-ip"
  address_type = "EXTERNAL"
  ip_version   = var.ip_version
}

resource "google_compute_global_address" "lb_ip_secondary" {
  count        = local.create_secondary_static_ip ? 1 : 0
  project      = var.project
  name         = var.secondary_static_ip_name != "" ? var.secondary_static_ip_name : "${var.name}-lb-ip-secondary"
  address_type = "EXTERNAL"
  ip_version   = local.secondary_ip_version
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  project = var.project
  name                  = "${var.name}-http-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_address = var.use_static_ip ? (
  local.requested_static_ip != "" ? local.requested_static_ip : google_compute_global_address.lb_ip[0].address
  ) : null
  }

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "${var.name}lb-ssl-cert"
  project=var.project
  managed {
    domains = local.all_domains
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
  ip_address            = var.use_static_ip ? (var.static_ip_address != "" ? var.static_ip_address : google_compute_global_address.lb_ip[0].address) : null
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule_secondary" {
  count                 = var.enable_dual_stack ? 1 : 0
  project               = var.project
  name                  = "${var.name}-http-forwarding-rule-secondary"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_version            = var.use_static_ip ? null : local.secondary_ip_version
  ip_address            = var.use_static_ip ? (
    local.requested_secondary_static_ip != "" ? local.requested_secondary_static_ip : google_compute_global_address.lb_ip_secondary[0].address
  ) : null
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule_secondary" {
  count                 = var.enable_dual_stack ? 1 : 0
  project               = var.project
  name                  = "${var.name}-https-forwarding-rule-secondary"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_version            = var.use_static_ip ? null : local.secondary_ip_version
  ip_address            = var.use_static_ip ? (
    local.requested_secondary_static_ip != "" ? local.requested_secondary_static_ip : google_compute_global_address.lb_ip_secondary[0].address
  ) : null
}
