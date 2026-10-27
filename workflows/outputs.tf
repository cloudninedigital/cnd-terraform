output "name" {
  description = "Name of the deployed workflow."
  value       = google_workflows_workflow.workflows_instance.name
}

output "id" {
  description = "Full resource id of the deployed workflow."
  value       = google_workflows_workflow.workflows_instance.id
}

output "service_account_email" {
  description = "Email of the service account the workflow runs as."
  value       = google_service_account.workflows_service_account.email
}
