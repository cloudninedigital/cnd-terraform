output "dataform_repository_id" {
  description = "The full GCP resource ID of the provisioned Dataform repository"
  value       = google_dataform_repository.repository.id
}

output "dataform_repository_name" {
  description = "The short name of the provisioned Dataform repository"
  value       = google_dataform_repository.repository.name
}

output "github_repository_url" {
  description = "The SSH clone URL of the created GitHub repository"
  value       = github_repository.client_dataform.ssh_clone_url
}

output "secret_version_id" {
  description = "The Secret Manager version storing the SSH private key"
  value       = google_secret_manager_secret_version.github_ssh_key_version.id
  sensitive   = true
}