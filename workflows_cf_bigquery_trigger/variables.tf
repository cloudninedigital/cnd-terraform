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
}

variable "table" {
  description = "BigQuery table (or table pattern) to trigger workflow on"
  type        = string
}

variable "workflow_template_file" {
  description = "template file used to define workflow steps"
  type        = string
  default     = "example.json"
}

variable "workflow_template_vars" {
  description = "vars to fill placeholders in template"
  type        = map
  default     = {}
}

variable "region" {
  description = "Region of most of the resources"
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "Zone of most of the resources"
  default     = "europe-west1-a"
}

variable "functions_region" {
  description = "Region where Cloud functions are deployed."
  default     = "europe-west1"
}