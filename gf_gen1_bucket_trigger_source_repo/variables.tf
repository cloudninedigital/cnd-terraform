variable "name" {
  description = "Name of the function."
  type        = string
}

variable "description" {
  description = "Description of the function."
  type        = string
}

variable "region" {
  description = "Region where function is living"
  default     = "europe-west1"
}

variable "runtime" {
  description = "Runtime where function is operating."
  type        = string
  default     = "python310"
}

variable "source_repo_name" {
  description = "Name of the Cloud Repository that hosts the function definition."
  type        = string
}

variable "project" {
  description = "Project ID."
  type        = string
}

variable "available_memory_mb" {
  description = "Amount of memory available in MB."
  type        = number
  default     = 2048
}

variable "max_instances" {
  description = "Amount of instances of this function allowed to run simultaneously"
  type        = number
  default     = 10
}

variable "min_instances" {
  description = "Minimum amount of instances running at any given time."
  type        = number
  default     = 0
}

variable "environment" {
  description = "Environment variables to be forwarded to function."
  type        = map(string)
  default     = {}
}

variable "trigger_resource" {
  description = "Name of resource that is supposed to trigger function"
  type        = string
}

variable "trigger_event_type" {
  description = "Type of event type the function should trigger on."
  type        = string
  default     = "google.storage.object.finalize"
}

variable "entry_point" {
  description = "Entry point method of the Cloud function."
  type        = string
  default     = "main_cloud_event"
}

variable "timeout" {
  description = "Timeout of the Cloud Function."
  type        = number
  default     = 540
}

variable "source_folder_relative_path" {
  description = "relative path to cloud function code"
  type        = string
  default = ".."
}