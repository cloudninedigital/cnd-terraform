output "job_name" {
  description = "Name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.job.name
}

output "job_uid" {
  description = "Unique identifier of the Cloud Run Job"
  value       = google_cloud_run_v2_job.job.uid
}

output "job_location" {
  description = "Location of the Cloud Run Job"
  value       = google_cloud_run_v2_job.job.location
}

output "scheduler_service_account_email" {
  description = "Email of the scheduler service account"
  value       = var.instantiate_scheduler ? google_service_account.scheduler_crs[0].email : null
}

output "scheduler_name" {
  description = "Name of the Cloud Scheduler job"
  value       = var.instantiate_scheduler ? google_cloud_scheduler_job.trigger[0].name : null
}