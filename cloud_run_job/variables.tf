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