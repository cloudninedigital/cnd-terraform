# REMOVE COMMENTS WHEN FIRST COMPOSER ENVIRONMENT HAS GONE LIVE 
# FILL BUCKET WITH THE DAG FOLDER BUCKET (AS CREATED BY COMPOSER) AND RE-APPLY
# module  "gcs_sync" {
#   source = "./modules/gcs_folder_sync"
#   bucket = var.bucket
# }

module "composer_environment" {
  source  = "./modules/composer_environment"
  name    = "fillinyourname-${terraform.workspace}"
  project = var.project
}