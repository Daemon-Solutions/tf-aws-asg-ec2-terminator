variable "name" {
  description = "The name to use for created resources"
  default     = "tf-aws-asg-ec2-terminator"
}

variable "customer" {
  description = "The customer name to use for Slack notifications"
  type        = string
}

variable "slack_url" {
  description = "The Slack webhook URL"
  default     = ""
}

variable "timeout" {
  description = "Lambda function timeout"
  default     = "60"
}

variable "auto_scaling_groups" {
  description = "List of ASG maps to create a CPU alarm for"
  default     = []
}

variable "fallback_alarms" {
  description = "List of fallback alarm maps to create a CPU alarm for"
  default     = []
}

# Notification options
variable "slack_emoji" {
  description = "The Slack emoji to display on messages"
  default     = ":terminator:"
}

variable "success_colour" {
  description = "Slack termination success colour"
  default     = "#36a64f"
}

variable "failure_colour" {
  description = "Slack termination failure colour"
  default     = "#ff0000"
}

variable "slack_subject" {
  description = "Slack subject (title)"
  default     = "Terminator"
}

