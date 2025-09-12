resource "aws_sns_topic" "alert_topic" {
  name = "${var.name}-topic"
}

resource "aws_sns_topic_subscription" "sns-topic" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alert_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com",
      "cloudwatch.amazonaws.com"]
    }

    resources = [aws_sns_topic.alert_topic.arn]
  }
}

resource "aws_cloudwatch_log_metric_filter" "yada" {
  name           = "${var.name}-mf"
  pattern        = var.log_pattern
  log_group_name = "/aws/lambda/${var.lambda_name}"

  metric_transformation {
    name      = "${var.name}-metric"
    namespace = "lambda_metric_filters"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "lmabda_failures" {
  alarm_name          = "${var.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.name}-metric"
  namespace           = "lambda_metric_filters"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alerting on failures in AWS lambda: ${var.lambda_name}"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.alert_topic.arn]
  ok_actions          = [aws_sns_topic.alert_topic.arn]
}