data "google_project" "project" {
  project_id = var.project
}

resource "google_secret_manager_secret_iam_member" "secret-access" {
  secret_id = var.container_config_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


resource "google_cloud_run_v2_service" "tagging_server" {
  name     = var.tagging_server_name
  location = var.region
  project = var.project
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
        min_instance_count = var.min_instance_count
        max_instance_count = var.max_instance_count
    }
    containers {
      image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
        ports {
        container_port = var.container_port
        }
        env {
        name = "POLICY_SCRIPT_URL"
        value = ""
        }
        env {
        name = "CONTAINER_CONFIG"
        value_source {
          secret_key_ref {
            secret = var.container_config_secret_id
            version = var.container_config_secret_version
          }
        }
        }
        env {
        name = "GOOGLE_CLOUD_PROJECT"
        value = var.project
        }    
        env {
        name = "PREVIEW_SERVER_URL"
        value = var.preview_server_url
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
  depends_on = [ google_secret_manager_secret_iam_member.secret-access ]
}

resource "google_cloud_run_v2_service" "preview_server" {
  name     = var.preview_server_name
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
        min_instance_count = 1
        max_instance_count = 1
    }
    containers {
      image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
        ports {
        container_port = var.container_port
        }
        env {
        name = "RUN_AS_PREVIEW_SERVER"
        value = "true"
        }
        env {
        name = "CONTAINER_CONFIG"
        value_source {
          secret_key_ref {
            secret = var.container_config_secret_id
            version = var.container_config_secret_version
          }
        }
        }
        env {
        name = "GOOGLE_CLOUD_PROJECT"
        value = var.project
        }   
        resources {
          limits = {
            cpu = 1
            memory="256Mi"
          }
          cpu_idle = true
        }       
    }
  }
    depends_on = [ google_secret_manager_secret_iam_member.secret-access ]
}

