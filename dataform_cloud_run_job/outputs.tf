output "job_name" {
  description = "Name of the Cloud Run job."
  value       = module.job.job_name
}

output "job_location" {
  description = "Region of the Cloud Run job."
  value       = module.job.job_location
}

output "invocation_service_account_email" {
  description = "Service account the Dataform invocation runs as (given, or created by the module)."
  value       = local.invocation_service_account
}

output "executor_service_account_email" {
  description = "Service account the job runs as."
  value       = module.job.executor_service_account_email
}
