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

variable "max_instance_count" {
  description = "maximum amount of instances"
  default = 6
}

variable "min_instance_count" {
  description = "minimum amount of instances"
  default = 0
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