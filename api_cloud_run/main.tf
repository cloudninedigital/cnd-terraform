data "google_project" "project" {
  project_id = var.project
}

resource "google_secret_manager_secret_iam_member" "secret-access" {
  secret_id = var.container_config_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


resource "google_cloud_run_v2_service" "api_server" {
  name     = var.name
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
        min_instance_count = var.min_instance_count
        max_instance_count = var.max_instance_count
    }
    containers {
      image = var.image
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
