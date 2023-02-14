resource "google_storage_bucket" "landing_bucket" {
  name          = "${var.project}-my-processing-bucket-${var.region}"
  location      = var.region
  storage_class = "STANDARD"
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_object" "orders_folder" {
  name          = "my_orders_folder/"
  content       = "Not really a directory, but it's empty."
  bucket        = "${google_storage_bucket.landing_bucket.id}"
}

module "cf_gcs_to_bq" {
  source = "./modules/gf_gen1_bucket_trigger_source_repo"
  name = "name_of_cloud_function"
  description = <<EOF
This function will trigger on new files saved in the trigger bucket
and process the data, finally inserting it into a BQ dataset
EOF
  source_repo_name = var.source_repo_name
  project = var.project
  trigger_resource = google_storage_bucket.landing_bucket.name
  entry_point = "main_cloud_event"
  environment = {
    ORDERS_FOLDER = google_storage_bucket_object.orders_folder.name
    ORDERS_BQ_TABLE = "${google_bigquery_table.orders_table.project}.${google_bigquery_table.orders_table.dataset_id}.${google_bigquery_table.orders_table.table_id}"
  }
}
