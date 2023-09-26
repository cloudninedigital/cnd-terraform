variable "name" {
  description = "name of alert policy"
  type = string
}

variable "documentation" {
  description = "Notification text in alert."
  type = string
  default = <<EOT
# bq-executor job failed
This policy is to alert when bq-executor job fails.

## Failed query

$${log.extracted_labels.query}

## Error message

$${log.extracted_labels.error}
EOT
}

variable "filter" {
  description = "filter condition on logs"
  type = string
  default = <<EOT
protoPayload.methodName="google.cloud.bigquery.v2.JobService.InsertJob"
severity=ERROR
protoPayload.metadata.jobChange.job.jobStatus.jobState="DONE"
protoPayload.metadata.jobChange.job.jobName:"bq-executor"
resource.type="bigquery_project"
  EOT
}

variable "label_extractors" {
    description = "label extractors"
    type = map(string)
    default = {
    query = "EXTRACT(protoPayload.metadata.jobChange.job.jobConfig.queryConfig.query)"
    error = "EXTRACT(protoPayload.metadata.jobChange.job.jobStatus.errorResult.message)"
  }
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
