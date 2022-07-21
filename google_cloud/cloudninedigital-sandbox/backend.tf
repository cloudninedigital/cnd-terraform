terraform {
 backend "gcs" {
   bucket  = "bucket-tfstate-cnd-sandbox"
   prefix  = "terraform/state"
 }
}