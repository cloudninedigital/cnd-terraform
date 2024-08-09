output "function_name" {
  description = "The name of the Cloud Function."
  value       = google_cloudfunctions2_function.function.name
  sensitive   = false
}

output "function_url" {
  description = "The URL of the deployed Cloud Function."
  value       = google_cloudfunctions2_function.function.service_config[0].url
  sensitive   = false
}

output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job."
  value       = google_cloud_scheduler_job.job[0].name
  sensitive   = false
  condition   = var.instantiate_scheduler
}

output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic."
  value       = google_pubsub_topic.topic.name
  sensitive   = false
}

output "bucket_name" {
  description = "The name of the Google Cloud Storage bucket."
  value       = google_storage_bucket.bucket.name
  sensitive   = false
}
