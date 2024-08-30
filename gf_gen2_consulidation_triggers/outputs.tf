output "cloud_function_name" {
  description = "The name of the Cloud Function created."
  value       = google_cloudfunctions2_function.function.name
}

output "cloud_function_url" {
  description = "The URL of the Cloud Function. Adjust the URL format if needed."
  value       = "https://REGION-run.googleapis.com/apis/run.googleapis.com/v1/projects/${var.project}/locations/${var.region}/services/${google_cloudfunctions2_function.function.name}"
}

output "cloud_function_service_account_email" {
  description = "The email of the service account used by the Cloud Function."
  value       = google_service_account.account.email
}

output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic created."
  value       = google_pubsub_topic.topic.name
}

# Handle the count parameter for Cloud Scheduler Job
output "cloud_scheduler_job_name" {
  description = "The name of the Cloud Scheduler job created."
  value       = var.instantiate_scheduler ? google_cloud_scheduler_job.job[0].name : "Not created"
}

output "cloud_scheduler_job_schedule" {
  description = "The schedule of the Cloud Scheduler job."
  value       = var.instantiate_scheduler ? google_cloud_scheduler_job.job[0].schedule : "Not created"
}

output "archive_file_md5" {
  description = "The MD5 hash of the source zip file."
  value       = data.archive_file.source.output_md5
}
