resource "google_cloud_run_v2_service" "api_server" {
  name     = var.name
  location = var.region
  project = var.project
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
