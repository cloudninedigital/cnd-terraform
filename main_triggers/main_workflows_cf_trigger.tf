module "workflows_cf_main_trigger" {
  source = "./modules/workflows_cf"
  name = "workflows-cf-bigquery-test-${terraform.workspace}"
  description = "a workflow triggered by a table update that calls the bigquery_http_function"
  project = var.project
  dataset = "some_dataset"
  table = "iets"
  trigger_type = "bq"
  cloudfunctions = [{
    "name": "bigquery_http_function"
  },{
    "name": "bigquery_http_function",
    "table_updated": "some_dataset.nogiets"
  }]
  functions_region = "europe-west1"
}