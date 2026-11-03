terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    # google_dataform_repository and google_project_service_identity are beta only.
    google-beta = {
      source = "hashicorp/google-beta"
    }
    # Without this, Terraform resolves github_* resources to the deprecated hashicorp/github.
    github = {
      source = "integrations/github"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
