variable "name" {
  description = "Name of workflow"
  type        = string
}

variable "description" {
  description = "Description of workflow"
  type        = string
}

variable "project" {
  description = "Project ID"
  type        = string
}

variable "dataset" {
  description = "BigQuery dataset to trigger workflow on"
  type        = string
  default     = ""
}

variable "table" {
  description = "BigQuery table (or table pattern) to trigger workflow on"
  type        = string
  default     = ""
}

variable "cloudfunctions" {
  description = "list of cloudfunction maps to execute in the flow"
  type        = list
  default     = [{name: "example_cf", table_updated: "some_dataset.iets"}]
}

variable trigger_type {
  description = "Type of trigger used to start workflow. Available options: http, schedule, gcs, bq"
  type = string
  default = "http"
}

variable "region" {
  description = "Region of the workflow"
  type        = string
  default     = "europe-west3"
}

variable "functions_region" {
  description = "Region where Cloud functions are deployed."
  type = string
  default     = "europe-west3"
}

variable "bucket_name" {
  description = "Name of bucket that triggers the workflow"
  type        = string
  default = ""
}

variable "schedule" {
  description = "The schedule on which to trigger the function."
  type        = string
  default     = "1 1 * * *"

}