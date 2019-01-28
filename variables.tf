variable "name" {
  description = "The name to use for created resources"
  type        = "string"
}

variable "send_slack" {
  description = "Toggle for sending Slack messages"
  default     = true
}

variable "slack_url" {
  description = "The Slack webhook URL"
  default     = ""
}

variable "fallback_alarm" {
  description = "Toggle for creating a fallback alarm for uses such as PagerDuty"
  default     = false
}

variable "fallback_sns_topic_arn" {
  description = "Fallback SNS topic if Terminator cannot resolve the main alarm"
  default     = ""
}

variable "fallback_additional_evaluation_periods" {
  description = "Additional evaluation periods before firing the fallback alarm"
  default     = 10
}

variable "auto_scaling_groups" {
  description = "List of ASG maps to create a CPU alarm for"
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
