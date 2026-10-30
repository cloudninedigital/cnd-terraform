# ---------------------------------------------------------------------------
# Optional browser access: Cloud Run nginx proxy with IAP (Google login) on
# its run.app URL -> Direct VPC egress -> VM private IP:8000.
# No public IP on the VM, no DNS, no load balancer. A custom domain / LB can
# be put in front of this service later.
# ---------------------------------------------------------------------------
locals {
  web_ui_source_ranges = length(var.web_ui_source_ranges) > 0 ? var.web_ui_source_ranges : [var.subnet_cidr]
  web_ui_members       = var.web_ui_members == null ? var.iap_members : var.web_ui_members

  nginx_conf = <<-EOT
    map $http_upgrade $connection_upgrade {
      default upgrade;
      ''      close;
    }
    server {
      listen 8080;
      client_max_body_size 100m;
      location / {
        proxy_pass http://${google_compute_instance.airbyte.network_interface[0].network_ip}:8000;
        proxy_http_version 1.1;
        # abctl's ingress routes on the host it was installed for (localhost).
        proxy_set_header Host localhost;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
      }
    }
  EOT
}

data "google_project" "this" {
  count      = var.enable_web_ui ? 1 : 0
  project_id = var.project
}

resource "google_project_service" "web_ui_apis" {
  for_each           = var.enable_web_ui && var.enable_apis ? toset(["run.googleapis.com", "iap.googleapis.com"]) : toset([])
  project            = var.project
  service            = each.value
  disable_on_destroy = false
}

# Runtime identity for the proxy; needs no roles.
resource "google_service_account" "web_ui" {
  count        = var.enable_web_ui ? 1 : 0
  project      = var.project
  account_id   = "${var.name}-ui"
  display_name = "Airbyte UI proxy (${var.name})"
}

# Direct VPC egress uses IPs from the subnet; allow those to reach the UI port.
resource "google_compute_firewall" "web_ui" {
  count         = var.enable_web_ui ? 1 : 0
  project       = var.project
  name          = "${var.name}-allow-ui-proxy"
  network       = local.network
  direction     = "INGRESS"
  source_ranges = local.web_ui_source_ranges
  target_tags   = ["${var.name}-iap"]

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }
}

resource "google_cloud_run_v2_service" "web_ui" {
  count               = var.enable_web_ui ? 1 : 0
  project             = var.project
  name                = "${var.name}-ui"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  iap_enabled         = true
  deletion_protection = false
  labels              = local.labels

  template {
    service_account = google_service_account.web_ui[0].email
    timeout         = "3600s"

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = local.network
        subnetwork = local.subnetwork
      }
    }

    containers {
      image   = var.web_ui_image
      command = ["/bin/sh", "-c"]
      args    = ["printf '%s' \"$NGINX_CONF\" > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]

      ports {
        container_port = 8080
      }

      env {
        name  = "NGINX_CONF"
        value = local.nginx_conf
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        cpu_idle = true
      }
    }
  }

  depends_on = [google_project_service.web_ui_apis, google_compute_firewall.web_ui]
}

# IAP's service agent must be allowed to invoke the service. Granted at project
# level so Project IAM Admin is sufficient (service-level IAM would need
# Cloud Run Admin). The agent is created when IAP is first enabled.
resource "google_project_iam_member" "iap_invoker" {
  count   = var.enable_web_ui && var.manage_iam ? 1 : 0
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-${data.google_project.this[0].number}@gcp-sa-iap.iam.gserviceaccount.com"

  depends_on = [google_cloud_run_v2_service.web_ui]
}

# Who may pass the Google login. Needs IAP Policy Admin.
resource "google_iap_web_cloud_run_service_iam_member" "web_ui_users" {
  for_each               = var.enable_web_ui && var.manage_iam ? toset(local.web_ui_members) : toset([])
  project                = var.project
  location               = var.region
  cloud_run_service_name = google_cloud_run_v2_service.web_ui[0].name
  role                   = "roles/iap.httpsResourceAccessor"
  member                 = each.value
}
