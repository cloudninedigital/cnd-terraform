# Step 1: Create the GitHub Repository, or look up the existing one
resource "github_repository" "client_dataform" {
  count = var.existing_github_repository == null ? 1 : 0

  name        = var.repository_name
  description = "Dataform transformations for ${var.repository_name}"
  visibility  = "private"
  auto_init   = true

  # A destroy archives the repository instead of deleting the Dataform code in it.
  archive_on_destroy = true
}

# Keeps repositories created before count was added from being replaced.
moved {
  from = github_repository.client_dataform
  to   = github_repository.client_dataform[0]
}

data "github_repository" "existing" {
  count = var.existing_github_repository == null ? 0 : 1

  name = var.existing_github_repository
}

locals {
  github_repository_name = one(concat(github_repository.client_dataform[*].name, data.github_repository.existing[*].name))
  github_ssh_clone_url   = one(concat(github_repository.client_dataform[*].ssh_clone_url, data.github_repository.existing[*].ssh_clone_url))
}

# Step 2: Generate SSH key pair
resource "tls_private_key" "dataform_key" {
  algorithm = "ED25519"
}

# Step 3: Add Public Key as a Deploy Key to GitHub
resource "github_repository_deploy_key" "dataform_deploy_key" {
  title      = "GCP Dataform Access Key"
  repository = local.github_repository_name
  key        = tls_private_key.dataform_key.public_key_openssh
  read_only  = false
}

# Step 4: Store Private Key in GCP Secret Manager
resource "google_secret_manager_secret" "github_ssh_key" {
  project   = var.project
  secret_id = "dataform-ssh-key-${var.repository_name}"

  replication {
    auto {}
  }
}

# The Dataform service agent only exists once the API has been used in the project;
# this creates it up front, so the IAM binding below does not fail on a fresh project.
resource "google_project_service_identity" "dataform" {
  provider = google-beta
  project  = var.project
  service  = "dataform.googleapis.com"
}

# Grant the Dataform Service Account access to read the SSH key secret
resource "google_secret_manager_secret_iam_member" "dataform_secret_accessor" {
  project   = var.project
  secret_id = google_secret_manager_secret.github_ssh_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_project_service_identity.dataform.member
}

resource "google_secret_manager_secret_version" "github_ssh_key_version" {
  secret = google_secret_manager_secret.github_ssh_key.id
  # Dataform expects the key as ssh-keygen writes it (OpenSSH format), not PKCS#8 PEM.
  secret_data = tls_private_key.dataform_key.private_key_openssh
}

# Step 5: Provision the Dataform Repository
resource "google_dataform_repository" "repository" {
  provider = google-beta
  project  = var.project
  region   = var.region
  name     = var.repository_name

  # Under strict act-as, workflow and release configurations without their own
  # service account run as this one. Null leaves it unset.
  service_account = var.service_account

  git_remote_settings {
    url            = local.github_ssh_clone_url
    default_branch = var.git_default_branch

    ssh_authentication_config {
      user_private_key_secret_version = google_secret_manager_secret_version.github_ssh_key_version.id
      # GitHub's public host key, not a credential.
      host_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    }
  }

  workspace_compilation_overrides {
    default_database = var.project
    schema_suffix    = var.schema_suffix
  }

  # Guarantees IAM permissions and the deploy key are active before Dataform tests the connection
  depends_on = [
    google_secret_manager_secret_iam_member.dataform_secret_accessor,
    github_repository_deploy_key.dataform_deploy_key,
  ]
}
