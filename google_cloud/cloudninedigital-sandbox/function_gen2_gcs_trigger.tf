# [START functions_v2_basic_gcs]

locals {
  trigger_bucket_gen2 = "cloudninedigital-sandbox-gcf-trigger-gen2-test-bucket"
}

resource "google_storage_bucket" "source-bucket" {
  provider = google-beta
  name     = "gcf-source-bucket"
  location = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_source_object" "source_object" {
  provider = google-beta
  name   = "functions-source.zip"
  bucket = google_storage_bucket.source-bucket.name
  source = "functions-source.zip"  # Add path to the zipped function source code
}

resource "google_storage_bucket" "trigger-bucket" {
  provider = google-beta
  name     = "gcf-trigger-bucket"
  location = var.region # The trigger must be in the same location as the bucket
  uniform_bucket_level_access = true
}

data "google_storage_project_service_account" "gcs_account" {
  provider = google-beta
}

# To use GCS CloudEvent triggers, the GCS service account requires the Pub/Sub Publisher(roles/pubsub.publisher) IAM role in the specified project.
# (See https://cloud.google.com/eventarc/docs/run/quickstart-storage#before-you-begin)
resource "google_project_iam_member" "gcs-pubsub-publishing" {
  provider = google-beta
  project = var.project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_service_account" "account" {
  provider     = google-beta
  account_id   = "test-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}

# Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "invoking" {
  provider = google-beta
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "event-receiving" {
  provider = google-beta
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "artifactregistry-reader" {
  provider = google-beta
  project = var.project
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_cloudfunctions2_function" "function" {
  provider = google-beta
  depends_on = [
    google_project_iam_member.event-receiving,
    google_project_iam_member.artifactregistry-reader,
  ]
  name = "test-function-gcs-trigger-gen2"
  location = var.region
  description = "a function in gen2 to test the gcs trigger"

  build_config {
    runtime     = "python310"
    entry_point = "hello_gcs" # Set the entry point in the code
    environment_variables = {
      BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.source-bucket.name
        source_object = google_storage_bucket_source_object.source_object.name
      }
    }
  }

  service_config {
    max_instance_count  = 3
    min_instance_count = 1
    available_memory    = "256M"
    timeout_seconds     = 60
    environment_variables = {
        SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.account.email
  }

  event_trigger {
    trigger_region = var.region # The trigger must be in the same location as the bucket
    event_type = "google.cloud.storage.source_object.v1.finalized"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.account.email
    event_filters {
      attribute = "bucket"
      value = google_storage_bucket.trigger-bucket.name
    }
  }
}
# [END functions_v2_basic_gcs]