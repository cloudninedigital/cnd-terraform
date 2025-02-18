data "google_project" "project" {
  project_id = var.project
}

locals {
  timestamp  = formatdate("YYMMDDhhmmss", timestamp())
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
  account_id   = replace("gcf-${var.name}", "_", "-")
  display_name = "Execution Service Account - used for both the cloud function and eventarc trigger in the test"
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

resource "google_project_iam_member" "datastoreUser" {
  project = var.project
  role     = "roles/datastore.user"
  member   = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "objectViewer" {
  project = var.project
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.jobUser]
}

resource "google_project_iam_member" "secretAccessor" {
  project = var.project
  role     = "roles/secretmanager.secretAccessor"
  member   = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.jobUser]
}

## Create and upload source zip to special created functions bucket 

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.root}/.."
  output_path = "/tmp/git-function-${local.timestamp}.zip"
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.project}-${var.name}-func"
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
    min_instance_count = 0
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
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
    event_type = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value = var.trigger_bucket
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
    google_project_iam_member.jobUser,
    google_project_iam_member.objectViewer
  ]
}

## alerting policy
module "alerting_policy" {
  source = "../alert_policy"
  count = var.alert_on_failure ? 1 : 0
  name = "${var.name}-alert-policy"
  filter ="resource.type=\"cloud_run_revision\" severity=ERROR resource.labels.service_name=\"${var.name}-function\""
  email_addresses = var.alert_email_addresses
}
