data "google_project" "project" {
  project_id = var.project
}

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

resource "google_project_service" "run" {
  provider           = google-beta
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  provider           = google-beta
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "account" {
  account_id   = "gcf-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}

# Permissions for pubsub service account (google managed, so no need to create)
resource "google_project_iam_member" "token-creating" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "event-receiving" {
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.invoking]
}

resource "google_project_iam_member" "artifactregistry-reader" {
  project = var.project
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.event-receiving]
}

resource "google_project_iam_member" "dataEditor" {
  project = var.project
  role     = "roles/bigquery.dataEditor"
  member   = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.artifactregistry-reader]
}

resource "google_project_iam_member" "jobUser" {
  project = var.project
  role     = "roles/bigquery.jobUser"
  member   = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.dataEditor]
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
    service_account_email=google_service_account.account.email
  }

  event_trigger {
    trigger_region = var.region
    service_account_email=google_service_account.account.email
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
    event_filters {
      attribute = "resourceName"
      value = "projects/${var.project}/datasets/*/tables/*"
      operator = "match-path-pattern"
    }

  }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.event-receiving,
    google_project_iam_member.artifactregistry-reader,
    google_project_iam_member.token-creating,
    google_project_iam_member.dataEditor,
    google_project_iam_member.jobUser
  ]
}