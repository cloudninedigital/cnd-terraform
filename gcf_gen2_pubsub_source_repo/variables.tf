variable "name" {
  description = "Name of the function."
  type = string
}

variable "description" {
  description = "Description of the pub/sub function."
  type = string
}

variable "region" {
  description = "Region where function is living"
  default = "europe-west1"
}

variable "runtime" {
  description = "Runtime where function is operating."
  type = string
  default = "python310"
}

variable "source_repo_name" {
  description = "Name of the Cloud Repository that hosts the function definition."
  type = string
}

variable "source_repo_branch" {
  description = "Branch name containing code to be deployed."
  type = string
  default = "main"
}

variable "project" {
  description = "Project ID."
  type = string
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

variable "schedule" {
  description = "The schedule on which to trigger the function."
  type = string
  default = "*/2 * * * *"

}