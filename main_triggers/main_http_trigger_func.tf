module "cf_http_trigger_bq_processing" {
  source = "./modules/gf_gen1_http_trigger_source_repo"
  name = "name_of_cloud_function_http"
  description = <<EOF
This function will trigger on new files saved in the trigger bucket
and process the data, finally inserting it into a BQ dataset
EOF
  source_repo_name = var.source_repo_name
  project = var.project
  entry_point = "main_http_event"
  environment = {
    ORDERS_FOLDER = google_storage_bucket_object.orders_folder.name
    ORDERS_BQ_TABLE = "${google_bigquery_table.orders_table.project}.${google_bigquery_table.orders_table.dataset_id}.${google_bigquery_table.orders_table.table_id}"
  }
}
