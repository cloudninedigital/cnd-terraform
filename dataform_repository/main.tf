# Step 1: Create the GitHub Repository
resource "github_repository" "client_dataform" {
  name        = var.repository_name
  description = "Dataform transformations for ${var.repository_name}"
  visibility  = "private"
  auto_init   = true
}

# Step 2: Generate SSH key pair
resource "tls_private_key" "dataform_key" {
  algorithm = "ED25519"
}

# Step 3: Add Public Key as a Deploy Key to GitHub
resource "github_repository_deploy_key" "dataform_deploy_key" {
  title      = "GCP Dataform Access Key"
  repository = github_repository.client_dataform.name
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

# Fetch the auto-generated Dataform Service Account for your project
data "google_project" "project" {
  project_id = var.project
}

# Grant the Dataform Service Account access to read the SSH key secret
resource "google_secret_manager_secret_iam_member" "dataform_secret_accessor" {
  project   = var.project
  secret_id = google_secret_manager_secret.github_ssh_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_secret_manager_secret_version" "github_ssh_key_version" {
  secret      = google_secret_manager_secret.github_ssh_key.id
  secret_data = tls_private_key.dataform_key.private_key_pem
}

# Step 5: Provision the Dataform Repository
resource "google_dataform_repository" "repository" {
  project = var.project
  region  = var.region
  name    = var.repository_name

  git_remote_settings {
    url            = github_repository.client_dataform.ssh_clone_url
    default_branch = var.git_default_branch

    # Correct SSH Authentication Block
    ssh_authentication_config {
      user_private_key_secret_version = google_secret_manager_secret_version.github_ssh_key_version.id
      host_public_key                  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    }
  }

  workspace_compilation_overrides {
    default_database = var.project
    schema_suffix    = var.schema_suffix
  }

  # Guarantees IAM permissions are completely active before Dataform tests the connection
  depends_on = [
    google_secret_manager_secret_iam_member.dataform_secret_accessor
  ]
}