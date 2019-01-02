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
      evaluation_periods = "2"
    },
  ]
}

resource "aws_sns_topic" "pagerduty_fallback" {
  name = "customer-prod-pagerduty"
}

module "asg" {
  source    = "git::ssh://git@gogs.bashton.net/Bashton-Terraform-Modules/tf-aws-asg.git"
  name      = "customer-prod-asg"
  envname   = "terminator"
  service   = "terminator"
  ami_id    = "ami-25e7705c"
  subnets   = "${module.vpc.public_subnets}"
  user_data = "${data.template_cloudinit_config.config.rendered}"

  instance_type               = "t3.nano"
  associate_public_ip_address = true
  min                         = "2"
  max                         = "5"
}

data "template_file" "script" {
  template = "${file("templates/boot.sh.tpl")}"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.script.rendered}"
  }
}
