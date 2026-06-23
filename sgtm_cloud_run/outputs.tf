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
