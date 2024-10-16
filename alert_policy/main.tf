resource "google_monitoring_notification_channel" "email" {
  for_each = var.email_addresses
  display_name = "${var.name}-email-alert-channel-${each.key}"
  type         = "email"
  project = var.project
  labels = {
    email_address = each.value
  }
  force_delete = false
}

resource "google_monitoring_alert_policy" "main" {
  display_name = var.name
  project = var.project
  combiner     = "OR"
  conditions {
    display_name = "${var.name}-condition"
    condition_matched_log {
      filter = var.filter
      label_extractors = var.label_extractors
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.name]
  alert_strategy {
    notification_rate_limit {
      period = var.notification_rate_limit
    }
  }

  documentation {
    content = var.documentation
    mime_type = "text/markdown"
  }

  depends_on = [google_monitoring_notification_channel.email]
}