## Create and upload source zip to special created functions bucket

locals {
  timestamp = formatdate("YYMMDDhhmmss", timestamp())
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.root}/.."
  output_path = "/tmp/git-function-${local.timestamp}.zip"
  excludes = concat(
    tolist(fileset("${path.root}/..", "terraform/**")),
    tolist(fileset("${path.root}/..", ".git/**")),
    tolist(fileset("${path.root}/..", ".github/**")),
    tolist(fileset("${path.root}/..", "docs/**")),
    tolist(fileset("${path.root}/..", "tests/**")),
    tolist(fileset("${path.root}/..", "*.md")),
  )
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.app_name}-source"
  location = var.region
}

resource "google_storage_bucket_object" "archive" {
  name   = "source.zip#${data.archive_file.source.output_md5}"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path
}

output "bucket_name" {
  value = google_storage_bucket.bucket.name
}

output "bucket_object_name" {
  value = google_storage_bucket_object.archive.name
}