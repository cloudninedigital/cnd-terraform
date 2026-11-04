data "google_project" "project" {
  project_id = var.project
}

resource "google_project_service" "run_api" {
  project            = var.project
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  project            = var.project
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Optional: create the (empty) secret that holds the GTM container config.
# The value (a secret version) is always added outside Terraform, so the config
# string never ends up in code, tfvars or state. The Cloud Run services need that
# version before they can start: create the secret first, add the version, then
# deploy the rest (see the create_container_config_secret description).
resource "google_secret_manager_secret" "container_config" {
  count     = var.create_container_config_secret ? 1 : 0
  project   = var.project
  secret_id = var.container_config_secret_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_iam_member" "secret-access" {
  secret_id = var.create_container_config_secret ? google_secret_manager_secret.container_config[0].secret_id : var.container_config_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.secretmanager_api]
}


resource "google_cloud_run_v2_service" "tagging_server" {
  name     = var.tagging_server_name
  location = var.region
  project = var.project
  ingress = var.ingress

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
        dynamic "startup_probe" {
          for_each = var.enable_startup_probe ? [1] : []
          content {
            http_get {
              path = var.health_check_path
              port = tonumber(var.container_port)
            }
            period_seconds    = var.startup_probe_period_seconds
            timeout_seconds   = var.startup_probe_timeout_seconds
            failure_threshold = var.startup_probe_failure_threshold
          }
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
        value = var.preview_server_url != "" ? var.preview_server_url : google_cloud_run_v2_service.preview_server.uri
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
  depends_on = [
    google_project_service.run_api,
    google_secret_manager_secret_iam_member.secret-access
  ]
}

resource "google_cloud_run_v2_service" "preview_server" {
  name     = var.preview_server_name
  location = var.region
  project  = var.project
  ingress  = var.ingress

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
        dynamic "startup_probe" {
          for_each = var.enable_startup_probe ? [1] : []
          content {
            http_get {
              path = var.health_check_path
              port = tonumber(var.container_port)
            }
            period_seconds    = var.startup_probe_period_seconds
            timeout_seconds   = var.startup_probe_timeout_seconds
            failure_threshold = var.startup_probe_failure_threshold
          }
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
    depends_on = [
      google_project_service.run_api,
      google_secret_manager_secret_iam_member.secret-access
    ]
}

resource "google_cloud_run_v2_service_iam_member" "tagging_public" {
  name     = google_cloud_run_v2_service.tagging_server.name
  project  = var.project
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "preview_public" {
  name     = google_cloud_run_v2_service.preview_server.name
  project  = var.project
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
