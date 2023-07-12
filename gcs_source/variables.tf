variable "region" {
  description = "Region where function is living."
  default     = "europe-west1"
}

variable "app_name" {
  description = "Name of the function."
  type        = string
}

variable "project" {
  description = "Project ID."
  type        = string
}

variable "stage" {
  description = "Stage of deployment."
  type        = string
}
