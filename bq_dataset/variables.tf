variable "dataset_id" {
    description = "The ID of the dataset to create"
    type = string
}

variable "region" {
    description = "The region to create the dataset in"
    type = string
    default = "EU"
}

variable "friendly_name" {
    description = "The friendly name of the dataset to create"
    type = string
    default = ""
}

variable "description" {
    description = "The description of the dataset to create"
    type = string
    default = ""
}

variable "default_table_expiration_ms" {
    description = "The default lifetime of all tables in the dataset, in milliseconds"
    type = number
    default = 0
}

variable "default_partition_expiration_ms" {
    description = "The default lifetime of all partitions in the dataset, in milliseconds"
    type = number
    default = 0
}

variable "tables" {
    description = "The tables to create in the dataset"
    type        = map(
        object({
            table_id = string
            partition_table = optional(bool, true)
            partition_type = optional(string, "DAY")
            partition_field = optional(string)
            require_partition_filter = optional(bool, false)
            schema = list(object({
                name = string
                type = string
                mode = optional(string, "NULLABLE")
                description = optional(string, "")
            }))
        })
    )

    default = {}
}