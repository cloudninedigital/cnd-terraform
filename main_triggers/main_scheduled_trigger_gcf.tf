module "cgf_pubsub" {
  source             = "./modules/gcf_gen2_pubsub_source_repo"
  name               = var.application_name
  description        = <<EOF
  This function will trigger when a new pubsub message is published.
EOF
  source_repo_name   = var.source_repo_name
  source_repo_branch = var.source_repo_branch
  project            = var.project
  entry_point        = "main_pubsub"
  environment = {
    ORDERS_FOLDER   = google_storage_bucket_object.orders_folder.name
    ORDERS_BQ_TABLE = "${google_bigquery_table.orders_table.project}.${google_bigquery_table.orders_table.dataset_id}.${google_bigquery_table.orders_table.table_id}"
  }
  schedule = "*/2 * * * *"

  stage = terraform.workspace
}
