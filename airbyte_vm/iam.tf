# ---------------------------------------------------------------------------
# Service account used by the VM and (via ADC/metadata server) by the
# Airbyte BigQuery destination. No JSON key is created.
# ---------------------------------------------------------------------------
resource "google_service_account" "airbyte" {
  project      = var.project
  account_id   = "${var.name}-vm"
  display_name = "Airbyte VM (${var.name})"
}

resource "google_bigquery_dataset" "target" {
  count       = var.create_dataset ? 1 : 0
  project     = var.project
  dataset_id  = var.bq_dataset_id
  location    = var.bq_location
  labels      = local.labels
  description = "Raw marketing data loaded by Airbyte."

  depends_on = [google_project_service.apis]
}

# Dataset-level grant: managed through the dataset's access list, so it does
# not need project IAM admin rights.
resource "google_bigquery_dataset_iam_member" "data_editor" {
  project    = var.project
  dataset_id = var.create_dataset ? google_bigquery_dataset.target[0].dataset_id : var.bq_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_service_account.airbyte.member
}

# ---------------------------------------------------------------------------
# Project / IAP / SA grants. Need Project IAM Admin (+ IAP Policy Admin).
# Set manage_iam = false when the deployer only has Editor; then run the
# commands from the `manual_iam_commands` output instead.
# ---------------------------------------------------------------------------
locals {
  sa_project_roles = [
    "roles/bigquery.jobUser",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
  human_members = var.grant_os_login ? var.iap_members : []
}

resource "google_project_iam_member" "sa_roles" {
  for_each = var.manage_iam ? toset(local.sa_project_roles) : toset([])
  project  = var.project
  role     = each.value
  member   = google_service_account.airbyte.member
}

resource "google_iap_tunnel_instance_iam_member" "tunnel" {
  for_each = var.manage_iam ? toset(var.iap_members) : toset([])
  project  = var.project
  zone     = var.zone
  instance = google_compute_instance.airbyte.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}

resource "google_project_iam_member" "os_login" {
  for_each = var.manage_iam ? toset(local.human_members) : toset([])
  project  = var.project
  role     = "roles/compute.osAdminLogin"
  member   = each.value
}

# OS Login users must be able to act as the VM's service account.
resource "google_service_account_iam_member" "sa_user" {
  for_each           = var.manage_iam && var.grant_sa_user ? toset(local.human_members) : toset([])
  service_account_id = google_service_account.airbyte.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
