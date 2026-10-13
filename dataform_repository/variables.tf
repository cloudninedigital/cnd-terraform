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