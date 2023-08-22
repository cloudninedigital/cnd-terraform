provider "google" {
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_project_service" "composer" {
  provider           = google-beta
  service            = "composer.googleapis.com"
  disable_on_destroy = false
}

# Enable IAM API
resource "google_project_service" "iam" {
  provider           = google-beta
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "account" {
  account_id   = "${var.name}-composer-account"
  display_name = "Test Service Account for Composer Environment"

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "composer-worker" {
  project = var.project
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "dataEditor" {
  project    = var.project
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.composer-worker]
}

resource "google_project_iam_member" "jobUser" {
  project    = var.project
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.dataEditor]
}

# Permissions for composer service account (google managed, so no need to create)
resource "google_service_account_iam_member" "custom_service_account" {
  provider           = google-beta
  service_account_id = google_service_account.account.id
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_composer_environment" "test" {
  name    = var.name
  region  = var.region
  project = var.project
  config {

    software_config {
      image_version = "composer-2-airflow-2"
      pypi_packages = var.pypi_packages
    }

    workloads_config {
      scheduler {
        cpu        = var.scheduler_cpu
        memory_gb  = var.scheduler_memory_gb
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = var.webserver_cpu
        memory_gb  = var.webserver_memory_gb
        storage_gb = 1
      }
      worker {
        cpu        = var.worker_cpu
        memory_gb  = var.worker_memory_gb
        storage_gb = 1
        min_count  = var.min_workers
        max_count  = var.max_workers
      }


    }
    environment_size = var.environment_size

    node_config {
      service_account = google_service_account.account.name
    }
  }

  depends_on = [google_project_service.composer, google_service_account.account]
}
