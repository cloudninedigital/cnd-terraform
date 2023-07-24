variable "name" {
  description = "Name of workflow"
  type        = string
}

variable "description" {
  description = "Description of workflow"
  type        = string
}

variable "bucket_name" {
  description = "Name of bucket that triggers the workflow"
  type        = string
}

variable "project" {
  description = "Project ID"
  type        = string
}

variable "workflow_template_file" {
  description = "template file used to define workflow steps"
  type        = string
  default     = "example.tftpl"
}

variable "region" {
  description = "Region of most of the resources"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone of most of the resources"
  default     = "europe-west1-a"
}

variable "functions_region" {
  description = "Region where Cloud functions are deployed."
  default     = "europe-west1"
}

variable "schedule" {
  description = "The schedule on which to trigger the function."
  type        = string
  default     = "1 1 * * *"

}