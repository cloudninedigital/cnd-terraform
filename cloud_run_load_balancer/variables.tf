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

variable "use_static_ip" {
  description = "Whether to attach a single static IP to the load balancer"
  type        = bool
  default     = false
}

variable "static_ip_name" {
  description = "Optional name for the reserved global static IP"
  type        = string
  default     = ""
}

variable "static_ip_address" {
  description = "Existing global static IP address to use (leave empty to auto-reserve when use_static_ip=true)"
  type        = string
  default     = ""
}