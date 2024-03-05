variable "project" {
  description = "Project ID."
  type = string
}

variable "tagging_server_name" {
  description = "Name of application"
}

variable "preview_server_name" {
  description = "Name of application"
}

variable "container_config_secret_id" {
  description = "key ID of Google Secret manager secret where container configuration ID is stored"
  default = "SGTM_CONTAINER_CONFIG"
}

variable "container_config_secret_version" {
  description = "version of Google Secret manager secret where container configuration ID is stored"
  default= "1"
}

variable "preview_server_url" {
  description = "URL of preview server, can only be known after preview server has been created. "
  default = ""
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
  default = 1
}

variable "container_port" {
  description = "port to use for container incoming traffic"
  default = "8080"
}