resource "aws_cloudwatch_event_rule" "rule_terminator" {
  count               = length(var.auto_scaling_groups)
  name                = "${var.name}-${var.auto_scaling_groups[count.index]["asg_name"]}"
  description         = "Terminator EC2 CPU event rule"
  schedule_expression = var.auto_scaling_groups[count.index]["schedule_expression"]
}

resource "aws_cloudwatch_event_target" "target_terminator" {
  count     = length(var.auto_scaling_groups)
  target_id = "${var.name}-${var.auto_scaling_groups[count.index]["asg_name"]}"
  rule = element(
    aws_cloudwatch_event_rule.rule_terminator.*.name,
    count.index,
  )
  arn = module.lambda.function_arn

  input = <<JSON
{
  "asg_name": "${var.auto_scaling_groups[count.index]["asg_name"]}",
  "period": "${var.auto_scaling_groups[count.index]["period"]}",
  "evaluation_periods": "${var.auto_scaling_groups[count.index]["evaluation_periods"]}",
  "datapoints_to_alarm": "${var.auto_scaling_groups[count.index]["datapoints_to_alarm"]}",
  "threshold": "${var.auto_scaling_groups[count.index]["threshold"]}",
  "customer": "${var.customer}"
}
JSON

}

