resource "aws_cloudwatch_metric_alarm" "alarm_terminator_cpu" {
  count               = "${length(var.auto_scaling_groups)}"
  alarm_name          = "${lookup(var.auto_scaling_groups[count.index], "name")}-${var.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${lookup(var.auto_scaling_groups[count.index], "evaluation_periods")}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${lookup(var.auto_scaling_groups[count.index], "period")}"
  statistic           = "Maximum"
  threshold           = "${lookup(var.auto_scaling_groups[count.index], "threshold")}"
  alarm_description   = "Max CPU alarm for ${lookup(var.auto_scaling_groups[count.index], "name")}"
  alarm_actions       = ["${aws_sns_topic.sns_topic.arn}"]

  dimensions {
    AutoScalingGroupName = "${lookup(var.auto_scaling_groups[count.index], "name")}"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_terminator_cpu_fallback" {
  count               = "${var.fallback_alarm ? length(var.auto_scaling_groups) : 0}"
  alarm_name          = "${lookup(var.auto_scaling_groups[count.index], "name")}-${var.name}-fallback"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${lookup(var.auto_scaling_groups[count.index], "evaluation_periods") + var.fallback_additional_evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${lookup(var.auto_scaling_groups[count.index], "period")}"
  statistic           = "Maximum"
  threshold           = "${lookup(var.auto_scaling_groups[count.index], "threshold")}"
  alarm_description   = "Max CPU alarm for ${lookup(var.auto_scaling_groups[count.index], "name")}"
  alarm_actions       = ["${var.fallback_sns_topic_arn}"]
  ok_actions          = ["${var.fallback_sns_topic_arn}"]

  dimensions {
    AutoScalingGroupName = "${lookup(var.auto_scaling_groups[count.index], "name")}"
  }
}
