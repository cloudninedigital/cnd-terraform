module "workflows_cf_bigquery_trigger" {
  source = "./modules/workflows_cf_bigquery_trigger"
  name = "workflows-cf-bigquery-test"
  description = "a workflow triggered by a table update that calls the bigquery_http_function"
  project = var.project
  dataset = "some_dataset"
  table = "iets"
  workflow_template_file = "example.tftpl"
}