variable "name" {
  description = "name of alert policy"
  type = string
}

variable "project" {
  description = "name of project"
  type = string
}

variable "documentation" {
  description = "Notification text in alert."
  type = string
  default = "An alert occured"
}

variable "filter" {
  description = "filter condition on logs"
}

variable "label_extractors" {
    description = "label extractors"
    type = map(string)
    default = {}
}

variable "notification_rate_limit" {
    description = "notification rate limit"
    type = string
    default = "300s"
}

variable "email_addresses" {
    description = "email addresses to send notifications to"
    type = map(string)
    default = {
      cnd_alerts = "alerting@cloudninedigital.nl"
    }
}
