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
  source_folder_relative_path = var.source_folder_relative_path
}

resource "google_service_account" "account" {
  account_id   = "${replace(var.name, "_", "-")}-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"

}

resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "artifactregistry-reader" {
  project    = var.project
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "dataEditor" {
  project    = var.project
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "jobUser" {
  project    = var.project
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "objectViewer" {
  project    = var.project
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_service_account.account.email}"
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
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector == "" ? "" : "ALL_TRAFFIC"
    environment_variables = var.environment
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.account.email
  }

  depends_on = [google_project_service.cloud_build_api, google_project_service.cloud_functions_api,
  google_service_account.account]

}

## alerting policy
module "alerting_policy" {
  source = "../alert_policy"
  count = var.alert_on_failure ? 1 : 0
  name = "${var.name}-alert-policy"
  filter = "resource.type=\"cloud_function\" severity=ERROR resource.labels.function_name=\"${var.name}\""
  email_addresses = var.alert_email_addresses
}
