module "gcs_folder_sync" {
  source                = "./modules/gcs_folder_sync"
  name                  = "${var.application_name}-bqexecutor-sync"
  gcs_bucket_file_path  = ""
  gcs_local_source_path = "../project_name/SQL/sql_scripts"
}

module "cf_http_trigger_bq_processing" {
  source      = "./modules/gf_gen2_http_trigger_source_repo"
  name        = var.application_name
  description = <<EOF
This function will trigger one or multiple bigquery script based upon BigQuery Executor logic
EOF
  project     = var.project
  region      = var.region
  entry_point = "main_bigquery_http_event"
  environment = {
    PROJECT           = var.project
    GCS_PROJECT       = var.project
    GCS_BUCKET_NAME   = module.gcs_folder_sync.bucket_name
    ENVIRONMENT        = terraform.workspace
  }
}

module "workflows_cf_main_trigger" {
  source = "./modules/workflows_cf"
  name = "${var.application_name}-workflow-${terraform.workspace}"
  description = "a workflow triggered by a table update that calls the bigquery_http_function"
  project = var.project
  dataset = "some_dataset_change_me"
  table = "some_table_change_me" # wildcard is allowed as a suffix
  trigger_type = "bq"
  cloudfunctions = [
    {
      "name": module.cf_http_trigger_bq_processing.function_name
    },
    {
      "name": module.cf_http_trigger_bq_processing.function_name
      "table_updated": "output_of_step1_table_change_me"
    }
  ]
  functions_region = var.region
  alert_on_failure = true

  depends_on = [
    module.gcs_folder_sync,
    module.cf_http_trigger_bq_processing
  ]
}
