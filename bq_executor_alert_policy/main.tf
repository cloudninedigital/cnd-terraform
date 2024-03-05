module "bq_executor_alerting_policy" {
  source = "../alert_policy"
  name = var.name
  filter = var.filter

  documentation = var.documentation

  email_addresses = var.email_addresses
  label_extractors = var.label_extractors
}
