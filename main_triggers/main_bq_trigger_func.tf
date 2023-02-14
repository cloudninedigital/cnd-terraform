module "cgf_bigquery" {
  source = "./modules/gf_gen2_bigquery_trigger_source_repo"
  name = "name_of_cloud_function"
  description = <<EOF
  This function will trigger when a bigquery table create or delete has happened
EOF
  source_repo_name = var.source_repo_name
  source_repo_branch = var.source_repo_branch
  project = var.project
  entry_point = "main_bigquery_event"
  environment = {
    project = var.project
    include_variables = "false"
    show_all_rows = "false"
    on_error_continue = "false"
    exclude_temp_ids = "false"
  }
}