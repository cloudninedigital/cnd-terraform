resource "google_project_service" "cloud_build_api" {
  project            = var.project
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc_api" {
  project            = var.project
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions_api" {
  project            = var.project
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
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

resource "google_project_service" "scheduler_api" {
  project            = var.project
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  project            = var.project
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_pubsub_topic" "topic" {
  name = "${var.name}_trigger_topic"

  depends_on = [
    google_project_service.pubsub_api
  ]
}

data "google_project" "project" {}

resource "google_service_account" "account" {
  account_id   = "${replace(var.name, "_", "-")}-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}

resource "google_project_iam_member" "secret_manager_access" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_service_account.account]
}

resource "google_project_iam_member" "token_creator_access" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  depends_on = [google_project_service.pubsub_api]
}

resource "google_project_iam_member" "token_creator_access_ce" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_service_account.account]
}

resource "google_project_iam_member" "run_invoker_access" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  depends_on = [google_project_service.pubsub_api]
}

resource "google_project_iam_member" "run_invoker_access_ce" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "dataEditor" {
  project    = var.project
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_service_account.account]
}

resource "google_project_iam_member" "jobUser" {
  project    = var.project
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_service_account.account]
}

resource "google_project_iam_member" "objectViewer" {
  project    = var.project
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_service_account.account]
}

resource "google_cloud_scheduler_job" "job" {
  # Deploy schedulers only if in production
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
    google_project_service.scheduler_api,
    google_pubsub_topic.topic,
    google_service_account.account
  ]
}


module "source_code" {
  source   = "../gcs_source"
  project  = var.project
  app_name = var.name
  source_folder_relative_path = var.source_folder_relative_path
}



resource "google_cloudfunctions2_function" "function" {
  name        = "${var.name}_function"
  location    = var.region
  description = var.description
  
  build_config {
    runtime               = var.runtime
    entry_point           = var.entry_point
    environment_variables = var.environment
    source {
      storage_source {
        bucket = module.source_code.bucket_name
        object = module.source_code.bucket_object_name
      }
    }
  }

  service_config {
    max_instance_count             = var.max_instances
    min_instance_count             = var.min_instances
    available_memory               = var.available_memory
    available_cpu                  = var.available_cpu
    timeout_seconds                = var.timeout
    environment_variables          = {
      CHECK_PROJECT=var.check_project
      WRITE_PROJECT=var.write_project
      WRITE_DATASET=var.write_dataset
      WRITE_TABLE=var.write_table
      CONFIGURATION_FILE_NAME=var.configuration_file_name
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.account.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.topic.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_pubsub_topic.topic,
    google_project_service.artifact_registry_api,
    google_service_account.account
  ]
}

## alerting policy
module "alerting_policy" {
  source = "../alert_policy"
  count = var.alert_on_failure ? 1 : 0
  name = "${replace(var.name, "_", "-")}-alert-policy"
  filter = "resource.type=\"cloud_function\" severity=ERROR resource.labels.function_name=\"${var.name}\""
}

## alerting policy of data quality mismatches
module "check_alerting_policy" {
  source = "../alert_policy"
  count = var.alert_on_failure ? 1 : 0
  name = "${replace(var.name, "_", "-")}-check-alert-policy"
  filter = "resource.type=\"cloud_run_revision\" textPayload:\"~Data Quality Checker mismatches~\" resource.labels.service_name=\"${replace(var.name, "_", "-")}-function\""
  documentation = <<EOT
    # data quality check job contained mismatches
    This policy is to alert when bq-executor job fails.

    ## Mismatches

    $${log.extracted_labels.mismatches}
    EOT
  label_extractors = {
    mismatches = "EXTRACT(textPayload)"
  }
  
}