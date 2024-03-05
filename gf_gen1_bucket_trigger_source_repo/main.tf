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

resource "google_project_service" "artifact_registry_api" {
  project            = var.project
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

module "source_code" {
  source   = "../gcs_source"
  project  = var.project
  app_name = var.name
  source_folder_relative_path = var.source_folder_relative_path
}

resource "google_cloudfunctions_function" "gcs_triggered_function" {
  name                  = var.name
  description           = var.description
  region                = var.region
  runtime               = var.runtime
  entry_point           = var.entry_point
  source_archive_bucket = module.source_code.bucket_name
  source_archive_object = module.source_code.bucket_object_name
  available_memory_mb   = var.available_memory_mb
  timeout               = var.timeout
  max_instances         = var.max_instances
  min_instances         = var.min_instances
  # This should be done in another way, it seems clunky
  environment_variables = var.environment
  event_trigger {
    event_type = var.trigger_event_type
    resource   = var.trigger_resource
  }

  depends_on = [google_project_service.cloud_build_api, google_project_service.cloud_functions_api]
}