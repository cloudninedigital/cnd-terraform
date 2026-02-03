variable "name" {
  description = "Name of application"
}
variable "resource_group_name" {
  description = "Name of the resource group in which to create the Function App."
  type        = string
}
variable "resource_group_location" {
  description = "Location of the resource group."
  type        = string
}
variable "source_file" {
  description = "Path to the directory containing the function code."
  type        = string
}

variable "requirements_source_file" {
  description = "Path to the directory containing the function code."
  type        = string
}

variable "python_version" {
  description = "Python version for the Function App (e.g., 3.8, 3.9, 3.10, 3.11, 3.12)."
  type        = string
  default     = "3.10"
}