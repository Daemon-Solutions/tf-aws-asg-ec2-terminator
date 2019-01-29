resource "aws_cloudwatch_metric_alarm" "alarm_terminator_cpu" {
  count               = "${length(var.auto_scaling_groups)}"
  alarm_name          = "${lookup(var.auto_scaling_groups[count.index], "asg_name")}-${var.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${lookup(var.auto_scaling_groups[count.index], "evaluation_periods")}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${lookup(var.auto_scaling_groups[count.index], "period")}"
  statistic           = "Maximum"
  threshold           = "${lookup(var.auto_scaling_groups[count.index], "threshold")}"
  alarm_description   = "Max CPU alarm for ${lookup(var.auto_scaling_groups[count.index], "asg_name")}"
  alarm_actions       = ["${aws_sns_topic.sns_topic.arn}"]

  dimensions {
    AutoScalingGroupName = "${lookup(var.auto_scaling_groups[count.index], "asg_name")}"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_terminator_cpu_fallback" {
  count               = "${length(var.fallback_alarms)}"
  alarm_name          = "${lookup(var.fallback_alarms[count.index], "asg_name")}-${var.name}-fallback"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${lookup(var.fallback_alarms[count.index], "evaluation_periods")}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${lookup(var.fallback_alarms[count.index], "period")}"
  statistic           = "Maximum"
  threshold           = "${lookup(var.fallback_alarms[count.index], "threshold")}"
  alarm_description   = "Fallback max CPU alarm for ${lookup(var.fallback_alarms[count.index], "asg_name")}"
  alarm_actions       = ["${aws_sns_topic.fallback_sns_topic.arn}"]
  ok_actions          = ["${aws_sns_topic.fallback_sns_topic.arn}"]

  dimensions {
    AutoScalingGroupName = "${lookup(var.fallback_alarms[count.index], "asg_name")}"
  }
}
