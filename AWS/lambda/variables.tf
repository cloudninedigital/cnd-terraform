variable "instance_name" {
  description = "Project name. Convenience variable for naming resources"
  type = string
}

variable "lambda_source_file" {
  description = "Path to source file relative to terraform folder."
  type =  string
}

variable "aws_region" {
  description = "Region in which to deploy current configuration."
  type        = string
  default     = "eu-west-3"
}

variable "wsgi_entrypoint" {
  description = "Path to the function that handles the wsgi entrypoint."
  type = string
  default = "aws.lambda_handler"
}

variable "measurements_entrypoint" {
  description = "Path to the function that handles the measurement calculation entrypoint."
  type = string
  default = "aws_measurements.lambda_handler_measurements"
}

variable "historical_nightly_update_entrypoint" {
  description = "Path to the function that handles the measurement calculation entrypoint."
  type = string
  default = "aws_measurements.lambda_handler_nightly_historical_update"
}

variable "measurements_specific_experiment_entrypoint" {
  description = "Path to the function that handles the measurement calculation entrypoint."
  type = string
  default = "aws_measurements.lambda_handler_specific_experiment_measurements"
}


variable "segment_builder_entrypoint" {
  description = "Path to the function that handles the measurement calculation entrypoint."
  type = string
  default = "aws_segment_builder.lambda_handler_segment_builder"
}

variable "python_package_name" {
  description = "Name of python package containing lambda handler."
  type = string
  default = "lug_abtest_monitoring_backend"
}

variable "environment" {
  description = "Environment in which to deploy current configuration."
  type        = string
}

variable "cors_origin" {
  description = "Origin to allow CORS requests from."
  type        = string
}

variable "analytics_tool" {
  description = "analytics tool to use in implementation"
  type = string
  default = "adobe_analytics"
}


variable "bigquery_project" {
  description = "bigquery GCP project (if applicable)"
  type = string
  default = ""
}

variable "properties" {
  description = "properties relevant for this deployment"
  type = string
  default = ""
}

variable "experiment_variables" {
  description = "experiment variables relevant for this deployment"
  type = string
  default = ""
}

variable "application_type" {
  description = "Type of application (monitoring or evaluation)"
  type = string
  default = "monitoring"
}