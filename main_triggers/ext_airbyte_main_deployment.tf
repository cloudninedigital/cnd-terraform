## be aware that this is a module not managed by us!
module "airbyte-infra" {
  source  = "artefactory/airbyte-infra/google"
  version = "0.1.2"
  project_id = var.project
  region     = "europe-west3" # List available regions with `gcloud compute regions list`
  zone       = "europe-west3-a"  
}