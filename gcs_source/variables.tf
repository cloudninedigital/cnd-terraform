variable "region" {
  description = "Region where function is living."
  default     = "europe-west1"
}

variable "app_name" {
  description = "Name of the function."
  type        = string
}

variable "source_folder_relative_path" {
  description = "relative path to cloud function code"
  type        = string
  default = ".."
}

variable "project" {
  description = "Project ID."
  type        = string
}
