terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {

  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {

  project = var.project
  region  = var.region
  zone    = var.zone
}
