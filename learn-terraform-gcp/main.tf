terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
#  credentials = file("<NAME>.json")

  project = "cloudninedigital-sandbox"
  region  = "europe-west4"
  zone    = "europe-west4-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
