module "workflows_cf_main_trigger" {
  source = "./modules/workflows"
  name = "workflows-dataform-test"
  description = "a workflow triggered by a table update that calls the bigquery_http_function"
  project = "cloudnine-digital"
  dataset = "some_dataset"
  table = "iets"
  trigger_type = "bq"
  dataform_pipelines = [{name: "example_dp", tag: "example_tag", repository: "dennis-dataform-test"}]
  dataform_region = "europe-west3"
  workflow_type = "dataform"
  service_account_name = replace("wf-dataform-test", "_", "-")
  alert_on_failure = true
}