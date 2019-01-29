resource "aws_cloudwatch_event_rule" "rule_terminator" {
  count               = "${length(var.auto_scaling_groups)}"
  name                = "${var.name}-${lookup(var.auto_scaling_groups[count.index], "asg_name")}"
  description         = "Terminator EC2 CPU event rule"
  schedule_expression = "${lookup(var.auto_scaling_groups[count.index], "schedule_expression")}"
}

resource "aws_cloudwatch_event_target" "target_terminator" {
  count     = "${length(var.auto_scaling_groups)}"
  target_id = "${var.name}-${lookup(var.auto_scaling_groups[count.index], "asg_name")}"
  rule      = "${element(aws_cloudwatch_event_rule.rule_terminator.*.name, count.index)}"
  arn       = "${module.lambda.function_arn}"

  input = <<JSON
{
  "asg_name": "${lookup(var.auto_scaling_groups[count.index], "asg_name")}",
  "period": "${lookup(var.auto_scaling_groups[count.index], "period")}",
  "evaluation_periods": "${lookup(var.auto_scaling_groups[count.index], "evaluation_periods")}",
  "datapoints_to_alarm": "${lookup(var.auto_scaling_groups[count.index], "datapoints_to_alarm")}",
  "threshold": "${lookup(var.auto_scaling_groups[count.index], "threshold")}",
  "customer": "${var.customer}"
}
JSON
}
