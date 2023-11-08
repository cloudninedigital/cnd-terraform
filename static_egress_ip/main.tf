resource "google_project_service" "compute_api" {
  project            = var.project
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess_api" {
  project            = var.project
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}


resource "google_compute_network" "net" {
  auto_create_subnetworks         = "false"
  delete_default_routes_on_create = "false"
  enable_ula_internal_ipv6        = "false"
  mtu                             = "1460"
  name                            = "${var.name}-net"
  project                         = var.project
  routing_mode                    = "REGIONAL"
  depends_on = [ google_project_service.compute_api ]
}

resource "google_compute_subnetwork" "subnet" {
  ip_cidr_range              = var.subnet_ip_range
  name                       = "${var.name}-subnet"
  network                    = google_compute_network.net.id
  private_ip_google_access   = "false"
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = var.project
  purpose                    = "PRIVATE"
  region                     = var.region
  stack_type                 = "IPV4_ONLY"
  depends_on = [ google_project_service.compute_api,
                 google_compute_network.net ]
}

resource "google_vpc_access_connector" "connector" {
  name          = "${var.name}-connector"
  ip_cidr_range = var.connector_ip_range
  network       = google_compute_network.net.name
  min_instances = var.min_instances
  max_instances = var.max_instances
  max_throughput = 1000
  region = var.region
  project= var.project
  depends_on = [ google_project_service.compute_api,
                 google_project_service.vpcaccess_api,
                 google_compute_network.net ]
}

resource "google_compute_firewall" "rules" {
  project = var.project
  name    = "${var.name}-allow-ssh"
  network = google_compute_network.net.name
  target_tags = ["vpc-connector"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.199.224.0/19"] #this is a specific range for serverless services of GCP
  depends_on = [ google_project_service.compute_api,
                 google_compute_network.net ]
}

resource "google_compute_router" "router" {
  encrypted_interconnect_router = "false"
  name                          = "${var.name}-router"
  network                       = google_compute_network.net.id
  project                       = var.project
  region                        = var.region
  depends_on = [ google_project_service.compute_api,
                 google_compute_network.net ]
}

resource "google_compute_address" "address" {
  name   = "${var.name}-ip"
  project= var.project
  region = google_compute_subnetwork.subnet.region
  depends_on = [ google_project_service.compute_api,
                 google_compute_subnetwork.subnet ]
}

resource "google_compute_router_nat" "nat_manual" {
  name   = "${var.name}-gateway"
  project = var.project
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.address.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on = [ google_project_service.compute_api,
                 google_compute_network.net,
                 google_compute_subnetwork.subnet,
                 google_compute_router.router,
                 google_compute_address.address ]
}

