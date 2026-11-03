variable "github_organization" {
  description = "The GitHub organization or owner name"
  type        = string
  default     = "cloudninedigital"
}

variable "git_default_branch" {
  description = "Default Git branch for the repository"
  type        = string
  default     = "main"
}

variable "schema_suffix" {
  description = "Schema suffix for workspace compilations (e.g., dev, stg, prd)"
  type        = string
  default     = null
}

variable "existing_github_repository" {
  description = "Name of an existing GitHub repository (in the github provider's owner) to connect instead of creating one. Dataform reads workflow_settings.yaml from its root; subdirectories are not supported. The deploy key needs a token with admin rights on it. Null: a repository named var.repository_name is created."
  type        = string
  default     = null
}

variable "service_account" {
  description = "Service account (email) the repository's workflow and release configurations run as. The Dataform service agent needs Service Account Token Creator on it. Null: not set."
  type        = string
  default     = null
}

variable "repository_name" {
  description = "The name of the Dataform repository that is being created"
  type        = string
}

variable "project" {
  description = "The GCP project ID where the resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region where the Dataform repository will be created"
  type        = string
}