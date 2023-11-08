variable "project" {
  description = "Project ID"
  type        = string
}

variable "name" {
    description = "General name that all sub-parts are based upon"
    type = string
}

variable "region" {
  description = "Region of most of the resources"
  type        = string
  default     = "europe-west3"
}

variable subnet_ip_range {
    description = "ip_range of subnet to be created"
    type = string
    default = "10.156.0.0/20"
}


variable connector_ip_range {
    description = "ip_range of vpc connector to be created"
    type = string
    default = "10.8.0.0/28"
}


variable "min_instances" {
    description = "minimum instances for vpc connector"
    type = number
    default= 2
}

variable "max_instances" {
    description = "maximum instances for vpc connector"
    type = number
    default= 10
}

