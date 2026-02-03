## Own service account that creates and runs the cloud run instance
resource "google_service_account" "account" {
  project            = var.project
  account_id   = replace("crj-${var.name}", "_", "-")
  display_name = "Service account - used for executing cloud run implementation"
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
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
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


resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.account.email}"

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
}

resource "google_project_iam_member" "object_admin" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "run_admin" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.account.email}"
}


resource "google_project_iam_member" "jobUser" {
  project = var.project
  role     = "roles/bigquery.jobUser"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "AIplatformServiceAgent" {
  project = var.project
  role     = "roles/aiplatform.serviceAgent"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "dataEditor" {
  project = var.project
  role     = "roles/bigquery.dataEditor"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "pubsub-publisher" {
  project = var.project
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:${google_service_account.account.email}"
}

## New set-up | 08-01-25  ##
# Cloud Run Job definition (shared)
resource "google_cloud_run_v2_job" "job" {
  name                = var.name
  location            = var.region
  project             = var.project
  deletion_protection = var.deletion_protection  # false 
  launch_stage        = var.launch_stage #  "BETA"
  labels              = var.labels

  template {
    task_count  = var.task_count # 1 GA4 set-up
    parallelism = var.parallelism # 1 GA4 set-up

    template {
      service_account = google_service_account.account.email
      timeout         = var.timeout_seconds

      containers {
        image = var.image

        dynamic "env" {
          for_each = var.environment
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }
      }

      dynamic "node_selector" {
        for_each = var.enable_gpu ? [1] : []
        content {
          accelerator = "nvidia-l4"
        }
      }

      dynamic "vpc_access" {
        for_each = var.vpc_connector == "" ? [] : [1]
        content {
          connector = var.vpc_connector
          egress    = "ALL_TRAFFIC"
        }
      }

      # gpu_zonal_redundancy_disabled = var.enable_gpu ? true : null
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
    ]
  }
}

# Scheduler resources (created only if instantiate_scheduler is true)
resource "google_service_account" "scheduler_crs" {
  count        = var.instantiate_scheduler ? 1 : 0
  account_id   = "${replace(var.name, "_", "-")}-scheduler"
  display_name = "Service Account for ${var.name} scheduler"
  description  = "Service account used by Cloud Scheduler to trigger ${var.name} Cloud Run job"
  project      = var.project
}

resource "google_project_iam_member" "scheduler_crs_cloudrun_invoker" {
  count   = var.instantiate_scheduler ? 1 : 0
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_crs[0].email}"
}

resource "google_cloud_scheduler_job" "trigger" {
  count        = var.instantiate_scheduler ? 1 : 0
  name         = "${var.name}-scheduler"
  description  = "Scheduler for ${var.name}"
  schedule     = var.schedule
  time_zone    = "Europe/Amsterdam"
  region       = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project}/jobs/${var.name}:run"
    oauth_token {
      service_account_email = google_service_account.scheduler_crs[0].email
    }
  }

  depends_on = [
    google_project_iam_member.scheduler_crs_cloudrun_invoker
  ]
}

## End New set-up ##

