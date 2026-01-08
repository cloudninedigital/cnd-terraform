variable "project" {
  description = "Project ID."
  type = string
}

variable "name" {
  description = "Name of application"
}

variable "image" {
  description = "URL of docker image"
}

variable "environment" {
  description = "Environment variables to be forwarded to function."
  type        = list(map(string))
  default     = []
}

variable "region" {
  description = "Region where function is living"
  default = "europe-west4"
}

variable "cpu" {
  description = "amount of cpus allocated per instance"
  default = 1
}

variable "container_port" {
  description = "port to use for container incoming traffic"
  default = "8080"
}

variable "max_instance_request_concurrency" {
  description = "max number of concurrent requests allowed on one instance"
  default = 80
}

variable "memory" {
  description = "amount of memory allocated per instance"
  default = "512Mi"
}

variable "domain" {
  description = "custom domain to map to"
  default = ""
}

variable "enable_gpu" {
  description = "Enable GPU support"
  type        = bool
  default     = false
}

variable "mapping_paths" {
  description = "path to map to different services"
  type = list(string)
  default = ["*"]
}

variable "timeout_seconds" {
  description = "Job timeout in seconds"
  type        = string
  default     = "14400s"
}

variable "vpc_connector" {
  description = "The name of the vpc connector needed (only relevant if a static IP is needed)"
  type        = string
  default     = ""
}

variable "schedule" {
  description = "Cron schedule for the job"
  type        = string
  default     = null
}

variable "instantiate_scheduler" {
  description = "Whether to instantiate the Cloud Scheduler job."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Environment variables for the job"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the Cloud Run Job."
  type        = bool
  default     = false
}

variable "launch_stage" {
  description = "The launch stage of the Cloud Run Job."
  type        = string
  default     = "BETA"
}

variable "task_count" {
  description = "Number of tasks to run for the job."
  type        = number
  default     = 10
}

variable "parallelism" {
  description = "Number of tasks to run in parallel."
  type        = number
  default     = 5
}


variable "docker_image_version" {
  description = "Version tag of the docker image"
  type        = string
}