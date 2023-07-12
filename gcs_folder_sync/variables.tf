variable "bucket" {
  description = "Bucket name. It will be appended with the stage name."
  type        = string
}


variable "gcs_local_source_path" {
  description = "The local path (without opening / ending slash) to the directory that needs to be synced, relative to the terraform/main.tf file location"
  type        = string
  default     = "../project_name/dags_folder"
}

variable "gcs_bucket_file_path" {
  description = "The path (with ending slash) to the directory that files need to be synced to in the gcs_bucket, provide empty string if not relevant"
  type        = string
  default     = "dags/"
}

variable "region" {
  description = "Region where function is living."
  default     = "europe-west1"
}

variable "stage" {
  description = "The stage of the pipeline, either 'dev', 'prd' or 'stg'."
  type        = string
}