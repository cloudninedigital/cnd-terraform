locals {
  trigger_bucket_gen1 = "cloudninedigital-sandbox-gcf-trigger-gen1-test-bucket" 
  region = "europe-west1"
}


resource "google_storage_bucket" "source_bucket" {
  provider = google-beta
  force_destroy            = true
  name     = "${var.project}-${local.region}-gcf-source-gcs-event"  # Every bucket name must be globally unique
  location = local.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "cloudninedigital_sandbox_gcf_trigger_gen1_test_bucket" {
  force_destroy            = true
  location                 = local.region
  name                     = local.trigger_bucket_gen1
  project                  = var.project
  storage_class            = "STANDARD"
}

resource "google_storage_bucket_object" "object" {
  provider = google-beta
  name   = "functions-source.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = "functions-source.zip"  # Add path to the zipped function source code
}

resource "google_cloudfunctions_function" "gcs_upload_test_function" {
  name = "test-function-gcs-upload"
  description = "a new function"
  region = local.region
  runtime = "python310"
  entry_point = "hello_gcs"  # Set the entry point 
  source_archive_bucket = google_storage_bucket.source_bucket.name
  source_archive_object = google_storage_bucket_object.object.name
  available_memory_mb = 256
  timeout = 60
  max_instances = 10
  event_trigger {
        event_type = "google.storage.object.finalize"
        resource = "${google_storage_bucket.cloudninedigital_sandbox_gcf_trigger_gen1_test_bucket.name}"
  }

}
