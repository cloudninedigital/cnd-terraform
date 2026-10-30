output "instance_name" {
  value = google_compute_instance.airbyte.name
}

output "zone" {
  value = var.zone
}

output "service_account_email" {
  description = "SA the Airbyte BigQuery destination runs as (leave the destination's credentials JSON empty to use it)."
  value       = google_service_account.airbyte.email
}

output "bq_dataset_id" {
  value = var.bq_dataset_id
}

output "iap_tunnel_command" {
  description = "Run locally, then open http://localhost:8000."
  value       = "gcloud compute start-iap-tunnel ${google_compute_instance.airbyte.name} 8000 --local-host-port=localhost:8000 --zone=${var.zone} --project=${var.project}"
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.airbyte.name} --tunnel-through-iap --zone=${var.zone} --project=${var.project}"
}

output "bootstrap_log_command" {
  description = "Follow the install progress (first install can take 15-30 min)."
  value       = "gcloud compute ssh ${google_compute_instance.airbyte.name} --tunnel-through-iap --zone=${var.zone} --project=${var.project} --command='sudo tail -f /var/log/airbyte-bootstrap.log'"
}

output "manual_iam_commands" {
  description = "Only when manage_iam = false: grants for a project IAM admin to run."
  value = var.manage_iam ? "" : join("\n", concat(
    [for r in local.sa_project_roles :
      "gcloud projects add-iam-policy-binding ${var.project} --member=${google_service_account.airbyte.member} --role=${r} --condition=None"],
    [for m in var.iap_members :
      "gcloud projects add-iam-policy-binding ${var.project} --member=${m} --role=roles/iap.tunnelResourceAccessor --condition=None"],
    [for m in local.human_members :
      "gcloud projects add-iam-policy-binding ${var.project} --member=${m} --role=roles/compute.osAdminLogin --condition=None"],
    [for m in local.human_members :
      "gcloud iam service-accounts add-iam-policy-binding ${google_service_account.airbyte.email} --project=${var.project} --member=${m} --role=roles/iam.serviceAccountUser"],
  ))
}
