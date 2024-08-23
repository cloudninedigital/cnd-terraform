output "function_name" {
  description = "The name of the Cloud Function."
  value = [for function in google_cloudfunctions2_function.function : function.name]
  sensitive   = false
}

output "function_url" {
  description = "The URL of the deployed Cloud Function."
  value = [for function in google_cloudfunctions2_function.function : function.service_config[0].uri]
  sensitive   = false
}

output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job."
  value       = var.instantiate_scheduler ? google_cloud_scheduler_job.job[0].name : null
  sensitive   = false
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
