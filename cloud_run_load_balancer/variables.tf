variable "project" {
  description = "Project ID."
  type = string
}

variable "name" {
  description = "Name of application"
}

variable "region" {
  description = "Region where function is living"
  default = "europe-west4"
}


variable "domain" {
  description = "custom domain to map to"
  default = ""
}

variable "mapping_services" {
  description = "List of paths and service names"
  type = map(object({
    name  = string
    path  = string
    service_name = string
    service_id = string
  }))
  default = {
    client1={ name = "client1", path = "/client1/*", service_id = "gcr.io/cloudrun/client1-app", service_name="client1"},
    client2={ name = "client2", path = "/client2/*", service_id = "gcr.io/cloudrun/client2-app", service_name="client2"}
  }
}

variable "strip_paths" {
  description = "whether or not to strip paths"
  type = bool
  default = false
}