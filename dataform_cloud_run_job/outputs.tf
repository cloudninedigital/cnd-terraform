output "job_name" {
  description = "Name of the Cloud Run job."
  value       = module.job.job_name
}

output "job_location" {
  description = "Region of the Cloud Run job."
  value       = module.job.job_location
}

output "executor_service_account_email" {
  description = "Service account the job runs as."
  value       = module.job.executor_service_account_email
}
