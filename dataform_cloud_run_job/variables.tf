variable "project" {
  description = "Project the Cloud Run job is deployed in."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Run job."
  type        = string
}

variable "region" {
  description = "Region of the Cloud Run job."
  type        = string
  default     = "europe-west4"
}

variable "repository" {
  description = "Dataform repository id (not the full resource name)."
  type        = string
}

variable "dataform_project" {
  description = "Project holding the Dataform repository. Empty: var.project."
  type        = string
  default     = ""
}

variable "dataform_region" {
  description = "Region of the Dataform repository. Empty: var.region."
  type        = string
  default     = ""
}

variable "git_commitish" {
  description = "Branch, tag or commit to compile."
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Dataform tags to run. Empty runs the whole graph."
  type        = list(string)
  default     = []
}

variable "vars" {
  description = "Fixed compilation vars, e.g. { stage = \"prd\" }."
  type        = map(string)
  default     = {}
}

variable "vars_from_env" {
  description = "Compilation vars read from an environment variable at run time: { dataform_var = \"ENV_NAME\" }. E.g. { client_id = \"CLIENT_ID\" } with CLIENT_ID set per execution by a workflow (see the workflows module's runtime_env_from_args). Unset or empty keeps the repository default."
  type        = map(string)
  default     = {}
}

variable "code_compilation_config" {
  description = "Extra codeCompilationConfig fields, e.g. { schemaSuffix = \"dev\" }. vars is set from var.vars / var.vars_from_env."
  type        = map(string)
  default     = {}
}

variable "include_dependencies" {
  description = "Also run the actions the tagged actions depend on."
  type        = bool
  default     = true
}

variable "include_dependents" {
  description = "Also run the actions that depend on the tagged actions."
  type        = bool
  default     = false
}

variable "full_refresh" {
  description = "Rebuild incremental tables from scratch."
  type        = bool
  default     = false
}

variable "invocation_service_account" {
  description = "Service account email the Dataform invocation runs as. Empty: the repository's default."
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Extra environment variables for the job (merged over the runner's own)."
  type        = map(string)
  default     = {}
}

variable "image" {
  description = "Any image with python3 on the PATH; the runner needs nothing beyond the standard library."
  type        = string
  default     = "python:3.12-slim"
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "timeout_seconds" {
  description = "Job timeout, e.g. \"3600s\". The job waits for the Dataform invocation to finish."
  type        = string
  default     = "3600s"
}

variable "max_retries" {
  type    = number
  default = 0
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "instantiate_scheduler" {
  description = "Run the job on its own schedule (instead of, or besides, from a workflow)."
  type        = bool
  default     = false
}

variable "schedule" {
  type    = string
  default = null
}

variable "alert_on_failure" {
  type    = bool
  default = false
}

variable "alert_email_addresses" {
  type = map(string)
  default = {
    cnd_alerts = "alerting@cloudninedigital.nl"
  }
}
