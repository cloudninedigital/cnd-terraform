## Create and upload source zip to special created functions bucket

locals {
  source_dir = "${path.root}/${var.source_folder_relative_path}"

  # Keep exclusions aligned between archive content and change detection hash.
  source_excludes = [
    "terraform/**",
    ".git/**",
    ".github/**",
    "docs/**",
    "tests/**",
    "*.md",
  ]

  included_source_files = setsubtract(
    fileset(local.source_dir, "**"),
    setunion([for pattern in local.source_excludes : fileset(local.source_dir, pattern)]...)
  )

  # Hash file paths + file bytes to avoid mtime/archive metadata churn.
  source_content_hash = sha256(join("", [
    for file in sort(tolist(local.included_source_files)) : "${file}:${filesha256("${local.source_dir}/${file}")}"
  ]))
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "/tmp/${var.app_name}_source.zip"
  excludes    = local.source_excludes
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.app_name}-source"
  location = var.region
}

resource "google_storage_bucket_object" "archive" {
  name   = "source.zip#${substr(local.source_content_hash, 0, 20)}"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path

  lifecycle {
    ignore_changes = [source]
  }
}

output "bucket_name" {
  value = google_storage_bucket.bucket.name
}

output "bucket_object_name" {
  value = google_storage_bucket_object.archive.name
}