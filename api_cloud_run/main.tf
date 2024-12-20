resource "google_project_service" "run" {
  provider           = google-beta
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

## Own service account that creates and runs the cloud run instance
resource "google_service_account" "account" {
  account_id   = replace("gcr-api-${var.name}", "_", "-")
  display_name = "Service account - used for executing cloud run implementation"
}


resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "artifactregistry-reader" {
  project = var.project
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "pubsub-publisher" {
  project = var.project
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:${google_service_account.account.email}"
}

resource "google_cloud_run_v2_service" "api_server" {
  name     = var.name
  location = var.region
  project = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.account.email
    scaling {
        min_instance_count = var.min_instance_count
        max_instance_count = var.max_instance_count
    }

    containers {
      image = var.image

      dynamic env {
        for_each = var.environment
        content {   
        name = env.value.name
        value = env.value.value
        }
      }

        ports {
        container_port = var.container_port
        }         
        resources {
          limits = {
            cpu = 1
            memory="512Mi"
          }
          cpu_idle = true
        }   
    }
  }
}


data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_v2_service.api_server.location
  project     = google_cloud_run_v2_service.api_server.project
  service     = google_cloud_run_v2_service.api_server.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

output "service_uri" {
  value= google_cloud_run_v2_service.api_server.uri
}