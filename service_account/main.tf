# Enable IAM API
resource "google_project_service" "iam" {
  provider           = google-beta
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "account" {
  account_id   = var.name
  display_name = var.display_name
  project = var.project

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "roles" {
  for_each = toset(var.roles)
  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.account.email}"
}
