module "sgtm_cloud_run" {
  source = "./modules/sgtm_cloud_run"
  tagging_server_name = "<tagging_server_name>"
  preview_server_name = "<preview_server_name>"
  project = var.project
  max_instance_count = 6
  min_instance_count = 3
}