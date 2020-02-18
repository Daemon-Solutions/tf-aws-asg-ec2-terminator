resource "aws_cloudwatch_metric_alarm" "alarm_terminator_cpu_fallback" {
  count               = length(var.fallback_alarms)
  alarm_name          = "${var.name}-${var.fallback_alarms[count.index]["asg_name"]}-fallback"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.fallback_alarms[count.index]["evaluation_periods"]
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.fallback_alarms[count.index]["period"]
  statistic           = "Maximum"
  threshold           = var.fallback_alarms[count.index]["threshold"]
  alarm_description   = "Fallback max CPU alarm for ${var.fallback_alarms[count.index]["asg_name"]}"
  alarm_actions       = [aws_sns_topic.fallback_sns_topic.arn]
  ok_actions          = [aws_sns_topic.fallback_sns_topic.arn]

  dimensions = {
    AutoScalingGroupName = var.fallback_alarms[count.index]["asg_name"]
  }
}

