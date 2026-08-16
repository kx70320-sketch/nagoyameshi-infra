# 1. SNSトピックの作成（dev通知用）
resource "aws_sns_topic" "nagoyameshi_alerts_dev" {
  name = "nagoyameshi-alerts-dev"
}

# 2. SNSサブスクリプション（メール通知設定）
resource "aws_sns_topic_subscription" "email_subscription_dev" {
  topic_arn = aws_sns_topic.nagoyameshi_alerts_dev.arn
  protocol  = "email"
  endpoint  = "kx7.0320@gmail.com" # ★ご自身のメールアドレスに変更
}

# 3. CloudWatchアラーム（CPU使用率が80%を超えたら通知）
resource "aws_cloudwatch_metric_alarm" "cpu_high_dev" {
  alarm_name          = "nagoyameshi-cpu-high-dev"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Dev CPU usage has exceeded 80%"
  alarm_actions       = [aws_sns_topic.nagoyameshi_alerts_dev.arn]

  dimensions = {
    ClusterName = "nagoyameshi-dev-cluster"
    ServiceName = "nagoyameshi-dev-service"
  }
}