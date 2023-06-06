data "google_project" "project" {
  project_id = var.project
}

## Dependency API's that need to be enabled

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

##  Permissions for pubsub service account to handle event-arc events (google managed, so no need to create)

resource "google_project_iam_member" "token-creating" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}


## Own service account that creates and runs the cloud function
resource "google_service_account" "account" {
  account_id   = "gcf-exec"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}


##  Permissions on the service account used by the function and Eventarc trigger

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

## Create and upload source zip to special created functions bucket 

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "git-function"
  output_path = "/tmp/git-function-${local.timestamp}.zip"
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.project}-functions"
  location = "EU"
}

resource "google_storage_bucket_object" "archive" {
  name   = "terraform-function.zip#${data.archive_file.source.output_md5}"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path
}


## Actual declaration of the cloud function

resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.region
  description = var.description

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    environment_variables = var.environment
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.archive.name
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