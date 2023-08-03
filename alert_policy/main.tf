resource "google_monitoring_notification_channel" "cnd_email" {
  display_name = "${var.name}_cnd_email_alert_channel"
  type         = "email"
  labels = {
    email_address = "alerting@cloudninedigital.nl"
  }
  force_delete = false
}

resource "google_monitoring_alert_policy" "main" {
  display_name = var.name
  combiner     = "OR"
  conditions {
    display_name = "${var.name}_condition"
    condition_matched_log {
      filter = var.filter
    }
  }

  notification_channels = [ google_monitoring_notification_channel.cnd_email.name ]
  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }
}