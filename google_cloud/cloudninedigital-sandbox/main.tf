resource "google_storage_bucket" "default" {
  name          = "bucket-tfstate-cnd-sandbox"
  force_destroy = false
  location      = "EU"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}