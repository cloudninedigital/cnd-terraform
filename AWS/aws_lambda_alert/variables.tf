variable "name" {
  description = "name of alert"
  type = string
}

variable "email_address" {
  description = "Email address to send alert to"
  type = string
}

variable "log_pattern" {
  description = "pattern to trigger the alert"
  type = string
}

variable "lambda_name" {
  description = "name of lambda to run alert on"
  type = string
}