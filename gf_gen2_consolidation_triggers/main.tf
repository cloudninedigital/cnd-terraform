# Required provider configuration
provider "google" {
  project = var.project
  region  = var.region
}

# provider "google-beta" {
#   project = var.project
#   region  = var.region
# }

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
  # provider           = google-beta
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  # provider           = google-beta
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

## IAM roles for Eventarc and Service Account
resource "google_project_iam_member" "eventarc_event_receiver" {
  project = var.project
  role    = "roles/logging.viewer"  # This role may be necessary to access audit logs
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "eventarc_log_reader" {
  project = var.project
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "eventarc_event_receiver_service_account" {
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
  depends_on = [google_project_service.eventarc]
}

resource "google_project_iam_member" "logging_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "token_creator_access" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  depends_on = [google_project_service.pubsub_api]
}

## Create and configure service account
resource "google_service_account" "account" {
  account_id   = replace("gcf-${var.name}", "_", "-")
  display_name = "Execution Service Account - used for both the cloud function and eventarc trigger in the test"
}

resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "event_receiving" {
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [
    google_project_iam_member.invoking,
    google_project_service.eventarc
  ]
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [
    google_project_iam_member.event_receiving,
    google_project_service.artifact_registry_api
  ]
}

resource "google_project_iam_member" "data_editor" {
  project = var.project
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [
    google_project_iam_member.artifact_registry_reader,
    google_project_service.cloud_build_api
  ]
}

resource "google_project_iam_member" "job_user" {
  project = var.project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [
    google_project_iam_member.data_editor,
    google_project_service.cloud_build_api
  ]
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
  depends_on = [
    google_project_iam_member.job_user,
    google_project_service.cloud_functions_api
  ]
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [
    google_project_iam_member.job_user,
    google_project_service.cloud_functions_api
  ]
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
resource "google_cloudfunctions2_function" "bq_function" {
  count = var.trigger_type == "bq" ? 1 : 0
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
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector == "" ? "" : "ALL_TRAFFIC"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.account.email
  }

  event_trigger {
      retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
      event_type            = "google.cloud.audit.log.v1.written"
      service_account_email = google_service_account.account.email
      trigger_region        = "global"

    event_filters {
      attribute = "serviceName"
      value     = "bigquery.googleapis.com"
    }
    event_filters {
      attribute = "methodName"
      value     = "google.cloud.bigquery.v2.JobService.InsertJob"
    }
    event_filters {
      attribute = "resourceName"
      value     = "projects/${var.project}/datasets/*/tables/*"
      operator  = "match-path-pattern"
    }
    }
  

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.eventarc_event_receiver_service_account,
    google_project_iam_member.logging_log_writer,
    google_project_iam_member.pubsub_subscriber,
    google_project_iam_member.token_creator_access,
    google_project_iam_member.data_editor,
    google_project_iam_member.job_user,
    google_project_iam_member.object_viewer
  ]
}


resource "google_cloudfunctions2_function" "gcs_function" {
  count = var.trigger_type == "gcs" ? 1 : 0
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
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector == "" ? "" : "ALL_TRAFFIC"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.account.email
  }

  event_trigger {
      event_type   = "google.cloud.storage.object.v1.finalized"
      retry_policy = "RETRY_POLICY_DO_NOT_RETRY"

      trigger_region = var.region

      event_filters {
          attribute = "bucket"
          value     = var.trigger_bucket
      }
    }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.eventarc_event_receiver_service_account,
    google_project_iam_member.logging_log_writer,
    google_project_iam_member.pubsub_subscriber,
    google_project_iam_member.token_creator_access,
    google_project_iam_member.data_editor,
    google_project_iam_member.job_user,
    google_project_iam_member.object_viewer
  ]
}




resource "google_cloudfunctions2_function" "pubsub_function" {
  count = var.trigger_type == "pubsub" ? 1 : 0
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
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector == "" ? "" : "ALL_TRAFFIC"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.account.email
  }

  event_trigger {
      event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
      retry_policy = "RETRY_POLICY_DO_NOT_RETRY"

      trigger_region = var.region
      pubsub_topic   = google_pubsub_topic.topic.id
    }

  depends_on = [
    google_project_service.cloud_build_api,
    google_project_service.cloud_functions_api,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.eventarc_event_receiver_service_account,
    google_project_iam_member.logging_log_writer,
    google_project_iam_member.pubsub_subscriber,
    google_project_iam_member.token_creator_access,
    google_project_iam_member.data_editor,
    google_project_iam_member.job_user,
    google_project_iam_member.object_viewer
  ]
}


resource "google_cloudfunctions2_function" "http_function" {
  count= var.trigger_type == "http" ? 1 : 0
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
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
    available_memory   = var.available_memory
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