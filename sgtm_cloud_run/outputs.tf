output "tagging_server_id" {
  description = "Cloud Run service ID for the tagging server"
  value       = google_cloud_run_v2_service.tagging_server.id
}
