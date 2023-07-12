variable "name" {
  description = "Name of the composer environment."
  type        = string
}

variable "project" {
  description = "Project where environment is living."
  type        = string

}

variable "region" {
  description = "Region where environment is living."
  type        = string
  default     = "europe-west1"
}

variable "pypi_packages" {
  description = "Map of pypi packages."
  type        = map(string)
  default = {
    numpy                 = ""
    pandas                = ""
    google-cloud-bigquery = ""
    scipy                 = ""
  }
}

variable "min_workers" {
  description = "Minimum amount of workers."
  type        = number
  default     = 1
}

variable "max_workers" {
  description = "Maximum amount of workers."
  type        = number
  default     = 3
}


variable "scheduler_cpu" {
  description = "vCPU's appointed to the scheduler."
  type        = number
  default     = 0.5
}

variable "scheduler_memory_gb" {
  description = "GB's of memory appointed to the scheduler."
  type        = number
  default     = 1.875
}

variable "webserver_cpu" {
  description = "vCPU's appointed to the scheduler."
  type        = number
  default     = 0.5
}

variable "webserver_memory_gb" {
  description = "GB's of memory appointed to the scheduler."
  type        = number
  default     = 1.875
}

variable "worker_cpu" {
  description = "vCPU's appointed to the scheduler."
  type        = number
  default     = 0.5
}

variable "worker_memory_gb" {
  description = "GB's of memory appointed to the scheduler."
  type        = number
  default     = 1.875
}

variable "environment_size" {
  description = "Size of environment."
  type        = string
  default     = "ENVIRONMENT_SIZE_SMALL"
}

