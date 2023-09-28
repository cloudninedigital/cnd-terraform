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

resource "google_project_service" "cloud_run_api" {
  project            = var.project
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

module "source_code" {
  source   = "../gcs_source"
  project  = var.project
  app_name = var.name
}


resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.region
  description = var.description
  project = var.project
  
  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    environment_variables = var.environment
    source {
      storage_source {
        bucket = module.source_code.bucket_name
        object = module.source_code.bucket_object_name
      }
    }
  }

  service_config {
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
    available_memory   = var.available_memory_mb
    timeout_seconds    = var.timeout
    environment_variables = var.environment
    all_traffic_on_latest_revision = true
  }

  depends_on = [google_project_service.cloud_build_api, google_project_service.cloud_functions_api]

}

## alerting policy
module "alerting_policy" {
  source = "../alert_policy"
  count = var.alert_on_failure ? 1 : 0
  name = "${var.name}-alert-policy"
  filter = "resource.type=\"cloud_function\" severity=ERROR resource.labels.function_name=\"${var.name}\""
}
