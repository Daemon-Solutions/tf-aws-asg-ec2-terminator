# Create the Lambda function.

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda?ref=v0.10.0"

  function_name = "${var.name}"
  description   = "Terminator for EC2 instances."
  handler       = "lambda.lambda_handler"
  runtime       = "python3.6"
  timeout       = 5

  source_path = "${path.module}/lambda.py"

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.lambda.json}"

  environment {
    variables = {
      SLACK_TITLE = "${var.name}"
      SLACK_URL   = "${var.slack_url}"
      SLACK_EMOJI = "${var.slack_emoji}"

      SUCCESS_COLOUR = "${var.success_colour}"
      FAILURE_COLOUR = "${var.failure_colour}"

      SLACK_SUBJECT = "${var.slack_subject}"
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "cloudwatch:GetMetricStatistics",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
    ]

    resources = [
      "*",
    ]
  }
}

# Topic for alert messages to be sent to.

resource "aws_sns_topic" "sns_topic" {
  name = "${var.name}"
}

# Topic for fallback alert messages to be sent to.

resource "aws_sns_topic" "fallback_sns_topic" {
  name = "${var.name}-fallback"
}

# Subscribe the Lambda function to the SNS topic.

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${aws_sns_topic.sns_topic.arn}"
  protocol  = "lambda"
  endpoint  = "${module.lambda.function_arn}"
}

# Add permission for SNS to execute the Lambda function.

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${module.lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.sns_topic.arn}"
}
