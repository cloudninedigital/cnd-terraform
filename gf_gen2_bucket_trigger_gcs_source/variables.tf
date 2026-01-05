variable "name" {
  description = "Name of the function."
  type = string
}

variable "description" {
  description = "Description of the pub/sub function."
  type = string
}

variable "project" {
  description = "Project ID."
  type = string
}

variable "region" {
  description = "Region where function is living"
  default = "europe-west4"
}

variable "trigger_bucket" {
  description = "Name of bucket that triggers the resource"
  type = string
}

variable "runtime" {
  description = "Runtime where function is operating."
  type = string
  default = "python39"
}

variable "available_memory" {
  description = "The amount of memory available for a function. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function"
  type = string
  default = "2G"
}

variable "max_instances" {
  description = "Amount of instances of this function allowed to run simultaneously"
  type = number
  default = 10
}

variable "environment" {
  description = "Environment variables to be forwarded to function."
  type = map(string)
  default = {}
}



variable "entry_point" {
  description = "Entry point method of the Cloud function."
  type = string
  default = "main_pubsub"
}

variable "timeout" {
  description = "Timeout of the Cloud Function."
  type = number
  default = 540
}

variable "alert_on_failure" {
  description = "Enable alerting policy on function failure"
  type        = bool
  default     = false
}

variable "email_addresses" {
  description = "Map of email addresses to notify on alert"
  type        = map(string)
  default     = {
    cnd_alerts = "alerting@cloudninedigital.nl"
  }
}