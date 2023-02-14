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

resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.region
  description = var.description

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    environment_variables = var.environment
    source {
      repo_source {
        project_id = var.project
        repo_name = var.source_repo_name
        branch_name = var.source_repo_branch
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = var.available_memory
    timeout_seconds    = 60
    environment_variables = var.environment
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
  }

  event_trigger {
    trigger_region = var.region
    retry_policy   = "RETRY_POLICY_RETRY"
    event_type     = "google.cloud.audit.log.v1.written"
    event_filters {
      attribute = "serviceName"
      value = "bigquery.googleapis.com"
    }
    event_filters {
      attribute = "methodName"
      value = "google.cloud.bigquery.v2.JobService.InsertJob"
    }

  }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api
  ]
}