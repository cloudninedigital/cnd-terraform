terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.46" # iap_enabled on google_cloud_run_v2_service (web UI); 7.2.0 lacks it
    }
  }
}
