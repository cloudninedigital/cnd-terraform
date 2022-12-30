resource "google_project_service" "cloud_build_api" {
  project            = var.project
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions_api" {
  project            = var.project
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloudfunctions_function" "gcs_triggered_function" {
  name = var.name
  description = var.description
  region = var.region
  runtime = var.runtime
  entry_point = var.entry_point
  source_repository {
    url = "https://source.developers.google.com/projects/${var.project}/repos/${var.source_repo_name}/moveable-aliases/main"
  }
  available_memory_mb = var.available_memory_mb
  timeout = var.timeout
  max_instances = var.max_instances
  # This should be done in another way, it seems clunky
  environment_variables = var.environment
  trigger_http = true

  depends_on = [google_project_service.cloud_build_api, google_project_service.cloud_functions_api]
}