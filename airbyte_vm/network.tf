resource "google_compute_network" "this" {
  count                   = var.create_network ? 1 : 0
  project                 = var.project
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "this" {
  count                    = var.create_network ? 1 : 0
  project                  = var.project
  name                     = "${var.name}-subnet"
  region                   = var.region
  network                  = google_compute_network.this[0].id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# IAP TCP forwarding range -> SSH and the Airbyte UI/API port.
resource "google_compute_firewall" "iap" {
  project       = var.project
  name          = "${var.name}-allow-iap"
  network       = local.network
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.name}-iap"]

  allow {
    protocol = "tcp"
    ports    = ["22", "8000"]
  }
}

resource "google_compute_router" "this" {
  count   = var.create_nat ? 1 : 0
  project = var.project
  name    = "${var.name}-router"
  region  = var.region
  network = local.network
}

resource "google_compute_router_nat" "this" {
  count                              = var.create_nat ? 1 : 0
  project                            = var.project
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
