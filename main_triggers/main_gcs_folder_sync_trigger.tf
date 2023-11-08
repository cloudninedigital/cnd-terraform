module "gcs_folder_sync" {
  source = "./modules/gcs_folder_sync"
  bucket = var.bucket
  gcs_bucket_file_path = ""
  gcs_local_source_path = "../project_name/SQL/sql_scripts"
}