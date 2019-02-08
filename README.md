# tf-aws-asg-ec2-terminator

Provides a CloudWatch event rule for given Auto Scaling Groups which monitors maximum CPU usage. Fires a Lambda function on a schedule to attempt to terminate any offending instances if the maximum CPU threshold is exceeded. Also provides a fallback alarm for use with PagerDuty.

## Notes
- This module will not terminate any instances if the current in service instance count is at the ASG minimum.
- This must be used with ASG's that have auto scaling policies in place. The `evaluation_periods` and `datapoints_to_alarm` metrics must not be set too low, or autoscaling will not have added new instances, possibly causing this function to fail to terminate the old ones due to the ASG count being at the minimum.
- This module does not provision new instances to replace the ones terminated.

```hcl
module "terminator" {
  source    = "../"
  name      = "samplecustomer-prod"
  slack_url = "https://hooks.slack.com/services/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"

  auto_scaling_groups = [
    {
      asg_name            = "${module.asg.asg_name}"
      threshold           = "90"
      period              = "60"
      evaluation_periods  = "20"
      datapoints_to_alarm = "15"
      schedule_expression = "rate(20 minutes)"
    },
  ]

  fallback_alarms = [
    {
      asg_name           = "${module.asg.asg_name}"
      threshold          = "90"
      period             = "60"
      evaluation_periods = "45"
    },
  ]
}
```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | The name to use for created resources | string | none | yes |
| customer | The customer name to use for Slack notifications | string | none | yes |
| slack_url | The Slack webhook URL | string | none | no |
| timeout | Lambda function timeout | string | 60 | no |
| auto_scaling_groups | List of ASG maps to create a CloudWatch event rule for | list | none | yes |
| fallback_alarms | List of ASG maps to create a fallback CPU alarm for if termination fails | list | none | no |
| slack_emoji | The Slack emoji to display on messages | string | :terminator: | no |
| success_colour | Slack termination success colour | string | #36a64f | no |
| failure_colour | Slack termination failure colour | string | #ff0000 | no |
| slack_title | Slack subject (title) | string | Terminator | no |

## Outputs

| Name | Description |
|------|-------------|
| fallback_sns_topic_arn | ARN of the fallback SNS topic created by this module |
