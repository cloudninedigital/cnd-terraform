variable "project" {
  description = "The GCP project ID."
  type        = string
}

variable "name" {
  description = "The name of the Cloud Function and other related resources."
  type        = string
}

variable "description" {
  description = "Description of the pub/sub function."
  type        = string
}

variable "region" {
  description = "Region where function is living."
  type        = string
  default     = "europe-west4"
}

variable "trigger_bucket" {
  description = "Name of the bucket that triggers the resource."
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime where function is operating."
  type        = string
  default     = "python39"
}

variable "available_memory" {
  description = "The amount of memory available for a function. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function"
  type        = string
  default     = "2G"
}

variable "available_cpu" {
    description = "The amount of CPU available for a function. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function"
    type        = string
    default     = "1"
}

variable "min_instances" {
  description = "Minimum amount of instances running at any given time."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Amount of instances of this function allowed to run simultaneously."
  type        = number
  default     = 10
}

variable "environment" {
  description = "Environment variables to be forwarded to function."
  type        = map(string)
  default     = {}
}

variable "entry_point" {
  description = "Entry point method of the Cloud Function."
  type        = string
  default     = "main_pubsub"
}

variable "timeout" {
  description = "Timeout of the Cloud Function."
  type        = number
  default     = 700
}

variable "instantiate_scheduler" {
  description = "Whether to instantiate the Cloud Scheduler job."
  type        = bool
  default     = false
}

variable "schedule" {
  description = "The schedule for the Cloud Scheduler job, in cron format."
  type        = string
  default     = ""
}

variable "function_region" {
  description = "The region for the Cloud Scheduler job."
  type        = string
  default     = "us-central1"
}

variable "vpc_connector" {
  description = "The name of the vpc connector needed (only relevant if a static IP is needed)"
  type        = string
  default     = ""
}

variable "event_triggers" {
  description = "List of event triggers for the Cloud Function."
  type = list(object({
    region         = string
    event_type     = string
    pubsub_topic   = optional(string)
    retry_policy   = string
    event_filters  = list(object({
      attribute = string
      value     = string
    }))
  }))
  default = []
}

variable "alert_on_failure" {
  description = "The schedule on which to trigger the function."
  type        = bool
  default     = false
}

variable "alert_email_addresses" {
  description = "Map of email addresses to send notifications to."
  type        = map(string)
  default     = {
    default = "alerting@cloudninedigital.nl"
  }
}

variable "trigger_type" {
  description = "Type of trigger for the Cloud Function."
  type        = string
  default     = ""
}
