module "cgf_bigquery" {
  source      = "./modules/gf_gen2_bigquery_trigger_source_repo"
  name        = var.application_name
  description = <<EOF
  This function will trigger when a bigquery table create or delete has happened
EOF
  project     = var.project
  entry_point = "main_bigquery_event"
  environment = {
    PROJECT           = var.project
    GCS_PROJECT       = var.project
    GCS_BUCKET_NAME   = var.bucket
    INCLUDE_VARIABLES = "false"
    SHOW_ALL_ROWS     = "false"
    ON_ERROR_CONTINUE = "false"
    EXCLUDE_TEMP_IDS  = "false"
  }
  stage = terraform.workspace
}

module "gcs_sync" {
  source                = "./modules/gcs_folder_sync"
  bucket                = var.bucket
  gcs_bucket_file_path  = ""
  gcs_local_source_path = "../project_name/SQL/sql_scripts"
  stage                 = terraform.workspace
}
