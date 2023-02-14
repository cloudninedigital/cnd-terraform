module "cgf_pubsub" {
  source = "./modules/gcf_gen2_pubsub_source_repo"
  name = "name_of_cloud_function"
  description = <<EOF
  This function will trigger when a new pubsub message is published.
EOF
  source_repo_name = var.source_repo_name
  source_repo_branch = var.source_repo_branch
  project = var.project
  trigger_resource = google_storage_bucket.landing_bucket.name
  entry_point = "main_cloud_event"
  environment = {
    ORDERS_FOLDER = google_storage_bucket_object.orders_folder.name
    ORDERS_BQ_TABLE = "${google_bigquery_table.orders_table.project}.${google_bigquery_table.orders_table.dataset_id}.${google_bigquery_table.orders_table.table_id}"
  }
  schedule = "*/2 * * * *"
}
