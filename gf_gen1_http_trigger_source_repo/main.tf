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

module "source_code" {
  source   = "../gcs_source"
  project  = var.project
  stage    = var.stage
  app_name = var.name
}

resource "google_cloudfunctions_function" "gcs_triggered_function" {
  name                  = "${var.name}-${var.stage}"
  description           = var.description
  region                = var.region
  runtime               = var.runtime
  entry_point           = var.entry_point
  source_archive_bucket = module.source_code.bucket_name
  source_archive_object = module.source_code.object_name
  available_memory_mb   = var.available_memory_mb
  timeout               = var.timeout
  max_instances         = var.max_instances
  # This should be done in another way, it seems clunky
  environment_variables = var.environment
  trigger_http          = true

  depends_on = [google_project_service.cloud_build_api, google_project_service.cloud_functions_api]
}