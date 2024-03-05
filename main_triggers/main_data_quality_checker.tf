module "cf_data_quality_checker" {
  source      = "./modules/gcf_gen2_data_quality_checker"
  name        = "dq_checker"
  schedule = "1 2 * * *"
  configuration_file_name = "configuration.json"
  description = <<EOF
This function checks data quality based upon an input configuration
EOF
  project     = var.project
  entry_point = "main_scheduled_data_quality_check"
  check_project = var.project
  write_project = var.project
  write_dataset = "data_quality_checks"
  write_table = "example"
  alert_on_failure = true
}