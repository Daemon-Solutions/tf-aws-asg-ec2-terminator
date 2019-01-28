# tf-aws-asg-ec2-terminator

Provides a CloudWatch alarm for given Auto Scaling Groups which monitors maximum CPU usage. Fires a Lambda function to attempt to terminate the offending instances if the maximum CPU threshold is exceed. Also provides a fallback alarm for use with PagerDuty.

## Notes
- This module will not terminate any instances if the current in service instance count is at the ASG minimum.
- This must be used with ASG's that have auto scaling policies in place. The periods of the ASG alarm can be set in a way that new instances are provisioned before the alarm fires to terminate the bad ones smoothly. Alternatively, you can set these low and use the fallback alarm for PagerDuty.
- This module does not provision new instances.

```hcl
module "terminator" {
  source    = "../"
  name      = "terminator-customer-prod"
  slack_url = "https://hooks.slack.com/services/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"

  fallback_alarm         = true
  fallback_sns_topic_arn = "${aws_sns_topic.pagerduty_fallback.id}"

  auto_scaling_groups = [
    {
      name               = "${module.asg.asg_name}"
      threshold          = "90"
      period             = "60"
      evaluation_periods = "30"
    },
  ]
}
```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | The name to use for created resources | string | none | yes |
| slack_url | The Slack webhook URL | string | none | no |
| fallback_alarm | Toggle for creating a fallback alarm for uses such as PagerDuty | boolean | false | no |
| fallback_sns_topic_arn | Fallback SNS topic if Terminator cannot resolve the main alarm | string | none | no |
| fallback_additional_evaluation_periods | Additional evaluation periods before firing the fallback alarm | string | 2 | no |
| auto_scaling_groups | List of ASG maps to create a CPU alarm for | list | none | yes |
| slack_emoji | The Slack emoji to display on messages | string | :terminator: | no |
| success_colour | Slack termination success colour | string | #36a64f | no |
| failure_colour | Slack termination failure colour | string | #ff0000 | no |
| slack_title | Slack subject (title) | string | Terminator | no |

## Outputs

None
