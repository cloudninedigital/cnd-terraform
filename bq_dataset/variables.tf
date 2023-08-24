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
        str,
        map(str, any)
    ) # map of table_id to table config

    default = {
        some_table = {
            partition_type = "DAY"
            partition_field = "some_date"
            require_partition_filter = false
            schema = [
                {
                    name = "some_date",
                    type ="DATE",
                    mode ="REQUIRED",
                    description = "Date."
                },
                {
                    name = "order_id",
                    type ="STRING",
                    mode ="REQUIRED",
                    description = "Order ID."

                }
            ]
        }

    }
}