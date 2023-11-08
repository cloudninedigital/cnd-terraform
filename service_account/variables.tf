variable "name" {
    description = "The name of the service account."
    type        = string
}

variable "project" {
    description = "The ID of the project in which the resource belongs. If it is not provided, the provider project is used."
    type        = string
}

variable "display_name" {
    description = "The display name for the service account."
    type        = string
}

variable "roles" {
    description = "The list of roles to be applied to the service account."
    type        = list(string)
}