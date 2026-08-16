# 1. SNSトピックの作成（prd通知用）
resource "aws_sns_topic" "nagoyameshi_alerts_prd" {
  name = "nagoyameshi-alerts-prd"
}

# 2. SNSサブスクリプション（メール通知設定）
resource "aws_sns_topic_subscription" "email_subscription_prd" {
  topic_arn = aws_sns_topic.nagoyameshi_alerts_prd.arn
  protocol  = "email"
  endpoint  = "kx7.0320@gmail.com" # 
}

# 3. CloudWatchアラーム（CPU使用率が80%を超えたら通知）
resource "aws_cloudwatch_metric_alarm" "cpu_high_prd" {
  alarm_name          = "nagoyameshi-cpu-high-prd"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Prd CPU usage has exceeded 80%"
  alarm_actions       = [aws_sns_topic.nagoyameshi_alerts_prd.arn]

  dimensions = {
    ClusterName = "nagoyameshi-cluster"
    ServiceName = "nagoyameshi-service"
  }
}