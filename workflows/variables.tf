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

variable "stage" {
  description = "development stage to be used"
  type        = string
  default     = "dev"
}
 
variable "dataform_project" {
  description = "project in which dataform runs"
  type = string
  default = "n.a."
}

variable "dataform_pipelines" {
  description = "list of dataform pipeline maps to execute in the flow"
  type        = list
  default     = [{name: "example_dp", tag: "example_tag", repository: "dataform_repo_example"}]
}

variable "workflow_type" {
  description= "type of workflow to be triggered (determines the template being used). options are 'cf' (for cloud_functions) and 'dataform'"
  type = string
  default = "cf"
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

variable "dataform_region" {
  description = "Region where dataform is deployed."
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

variable "service_account_name" {
  description = "Name of service account to use for workflow"
  type        = string
}

variable "alert_on_failure" {
  description = "The schedule on which to trigger the function."
  type        = bool
  default     = false
}

variable "alert_email_addresses" {
  description = "email addresses to send notifications to"
  type = map(string)
  default = {
    cnd_alerts = "alerting@cloudninedigital.nl"
  }
}
