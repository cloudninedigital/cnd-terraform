output "tagging_server_id" {
  description = "Cloud Run service ID for the tagging server"
  value       = google_cloud_run_v2_service.tagging_server.id
}

output "tagging_server_uri" {
  description = "Direct run.app URL for the tagging server"
  value       = google_cloud_run_v2_service.tagging_server.uri
}

output "preview_server_id" {
  description = "Cloud Run service ID for the preview server"
  value       = google_cloud_run_v2_service.preview_server.id
}

output "preview_server_uri" {
  description = "Direct run.app URL for the preview server"
  value       = google_cloud_run_v2_service.preview_server.uri
}

output "container_config_secret_id" {
  description = "Secret Manager secret ID that holds the GTM container config"
  value       = var.create_container_config_secret ? google_secret_manager_secret.container_config[0].secret_id : var.container_config_secret_id
}
