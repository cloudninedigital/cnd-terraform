resource "google_storage_bucket" "landing_bucket" {
  name          = "${var.project}-my-processing-bucket-${var.region}"
  location      = var.region
  storage_class = "STANDARD"
  versioning {
    enabled = false
  }
}


module "cf_gcs_to_bq" {
  source           = "./modules/gf_gen1_bucket_trigger_source_repo"
  name             = var.application_name
  description      = <<EOF
This function will trigger on new files saved in the trigger bucket
and process the data, finally inserting it into a BQ dataset
EOF
  source_repo_name = var.source_repo_name
  project          = var.project
  trigger_resource = google_storage_bucket.landing_bucket.name
  entry_point      = "main_gcs_event"
  environment = {
    TARGET_BQ_TABLE = "${google_bigquery_table.target_table.project}.${google_bigquery_table.target_table.dataset_id}.${google_bigquery_table.target_table.table_id}"
  }
}
