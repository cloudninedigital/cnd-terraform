# Consulidation of gf_gen2_bucket_trigger_gcs_source | gf_gen2_pubsub_source_repo | gf_gen2_bigquery_trigger_source_repo

data "google_project" "project" {
  project_id = var.project
}

locals {
  timestamp = formatdate("YYMMDDhhmmss", timestamp())
}

## Dependency APIs that need to be enabled
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

resource "google_project_service" "artifact_registry_api" {
  project            = var.project
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_scheduler_api" {
  project            = var.project
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub_api" {
  project            = var.project
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

## Permissions for Pub/Sub service account to handle Eventarc events
resource "google_project_iam_member" "token_creator_access" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  depends_on = [google_project_service.pubsub_api]
}

## Own service account that creates and runs the cloud function
resource "google_service_account" "account" {
  account_id   = replace("gcf-${var.name}", "_", "-")
  display_name = "Execution Service Account - used for both the cloud function and eventarc trigger in the test"
}

## Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "event_receiving" {
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.invoking]
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.event_receiving]
}

resource "google_project_iam_member" "data_editor" {
  project = var.project
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.artifact_registry_reader]
}

resource "google_project_iam_member" "job_user" {
  project = var.project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.data_editor]
}

resource "google_project_iam_member" "datastore_user" {
  project = var.project
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "object_viewer" {
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.job_user]
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.job_user]
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

## Pub/Sub Topic
resource "google_pubsub_topic" "topic" {
  name = "${var.name}_trigger_topic"
  depends_on = [google_project_service.pubsub_api]
}

## Cloud Scheduler Job
resource "google_cloud_scheduler_job" "job" {
  count       = var.instantiate_scheduler ? 1 : 0
  name        = "${var.name}_scheduler"
  description = "A schedule for triggering the function"
  schedule    = var.schedule
  region      = var.function_region

  pubsub_target {
    topic_name = google_pubsub_topic.topic.id
    data       = base64encode("test")
  }
  depends_on = [
    google_project_service.cloud_scheduler_api,
    google_pubsub_topic.topic
  ]
}

## Dynamic block for Cloud Functions with event triggers
resource "google_cloudfunctions2_function" "function" {
  count       = var.instantiate_function ? 1 : 0
  name        = var.name
  location    = var.region
  description = var.description

  build_config {
    runtime               = var.runtime
    entry_point           = var.entry_point
    environment_variables = var.environment
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    max_instance_count             = var.max_instances
    min_instance_count             = var.min_instances
    available_memory               = var.available_memory
    available_cpu                  = var.available_cpu
    timeout_seconds                = var.timeout
    environment_variables          = var.environment
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.account.email
  }

  dynamic "event_trigger" {
    for_each = var.event_triggers
    content {
      trigger_region = event_trigger.value.region
      event_type     = event_trigger.value.event_type
      pubsub_topic   = event_trigger.value.pubsub_topic != "" ? event_trigger.value.pubsub_topic : null
      retry_policy   = event_trigger.value.retry_policy

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters != "" ? event_trigger.value.event_filters : []
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
        }
      }
    }
  }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.event_receiving,
    google_project_iam_member.artifact_registry_reader,
    google_project_iam_member.token_creator_access,
    google_project_iam_member.data_editor,
    google_project_iam_member.job_user,
    google_project_iam_member.object_viewer
  ]
}

## Alerting Policy Module
module "alerting_policy" {
  source              = "../alert_policy"
  count               = var.alert_on_failure ? 1 : 0
  name                = "${var.name}-alert-policy"
  filter              = "resource.type=\"cloud_function\" severity=ERROR resource.labels.function_name=\"${var.name}\""
  documentation       = "The function ${google_cloudfunctions2_function.function.name} failed. Please check the logs for more information."
  email_addresses     = var.alert_email_addresses
}
