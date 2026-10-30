locals {
  labels = merge({ component = "airbyte", managed-by = "terraform" }, var.labels)

  network    = var.create_network ? google_compute_network.this[0].id : var.network
  subnetwork = var.create_network ? google_compute_subnetwork.this[0].id : var.subnetwork

  install_args = join(" ", compact(concat(
    var.insecure_cookies ? ["--insecure-cookies"] : [],
    var.airbyte_chart_version != "" ? ["--chart-version", var.airbyte_chart_version] : [],
    var.extra_install_args,
  )))

  apis = ["compute.googleapis.com", "iap.googleapis.com", "bigquery.googleapis.com"]
}

resource "google_project_service" "apis" {
  for_each           = var.enable_apis ? toset(local.apis) : toset([])
  project            = var.project
  service            = each.value
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Boot disk (explicit, so the snapshot policy can attach to it)
# ---------------------------------------------------------------------------
resource "google_compute_disk" "boot" {
  project = var.project
  name    = "${var.name}-boot"
  zone    = var.zone
  type    = var.disk_type
  size    = var.disk_size_gb
  image   = var.image
  labels  = local.labels

  lifecycle {
    # A newer image in the family must not recreate the disk (and wipe Airbyte).
    ignore_changes = [image]
  }

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------------------------------------
# VM
# ---------------------------------------------------------------------------
resource "google_compute_instance" "airbyte" {
  project      = var.project
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["${var.name}-iap"]
  labels       = local.labels

  deletion_protection       = var.deletion_protection
  allow_stopping_for_update = true

  boot_disk {
    source      = google_compute_disk.boot.id
    auto_delete = false
  }

  network_interface {
    subnetwork = local.subnetwork
    # No access_config block => no public IP. Egress via Cloud NAT.
  }

  service_account {
    email  = google_service_account.airbyte.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("${path.module}/templates/startup.sh.tftpl", {
      abctl_version = var.abctl_version
      install_args  = local.install_args
    })
  }

  depends_on = [google_compute_router_nat.this]
}

# ---------------------------------------------------------------------------
# Daily snapshots
# ---------------------------------------------------------------------------
resource "google_compute_resource_policy" "snapshots" {
  count   = var.enable_snapshots ? 1 : 0
  project = var.project
  name    = "${var.name}-daily-snapshots"
  region  = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.snapshot_start_time
      }
    }
    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      labels            = local.labels
      storage_locations = [var.region]
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "snapshots" {
  count   = var.enable_snapshots ? 1 : 0
  project = var.project
  name    = google_compute_resource_policy.snapshots[0].name
  disk    = google_compute_disk.boot.name
  zone    = var.zone
}
