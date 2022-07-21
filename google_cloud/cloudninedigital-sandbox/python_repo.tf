resource "google_artifact_registry_repository" "core-python-repo" {
  provider = google-beta

  location = var.region
  repository_id = "cnd-python-core"
  description = "A repository for core python packages developed at Cloud Nine Digital."
  format = "python"
}

resource "google_service_account" "repo-account" {
  provider = google-beta

  account_id   = "cnd-python-core-user"
  display_name = "Repository Service Account"
}

resource "google_artifact_registry_repository_iam_member" "repo-iam" {
  provider = google-beta

  location = google_artifact_registry_repository.core-python-repo.location
  repository = google_artifact_registry_repository.core-python-repo.name
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.repo-account.email}"
}