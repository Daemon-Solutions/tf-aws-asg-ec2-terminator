module "terminator" {
  source    = "../"
  slack_url = "https://hooks.slack.com/services/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"
  customer  = "samplecustomer"

  auto_scaling_groups = [
    {
      asg_name            = module.asg.asg_name
      threshold           = "90"
      period              = "60"
      evaluation_periods  = "20"
      datapoints_to_alarm = "15"
      schedule_expression = "rate(20 minutes)"
    },
  ]

  fallback_alarms = [
    {
      asg_name           = module.asg.asg_name
      threshold          = "90"
      period             = "60"
      evaluation_periods = "45"
    },
  ]
}

module "asg" {
  source          = "git::ssh://git@gitlab.com/claranet-pcp/terraform/aws/tf-aws-asg.git"
  name            = "web-asg"
  envname         = "terminator"
  service         = "terminator"
  ami_id          = "ami-25e7705c"
  security_groups = [aws_security_group.terminator.id]
  subnets         = module.vpc.public_subnets
  user_data       = data.template_cloudinit_config.config.rendered

  instance_type               = "t3.nano"
  associate_public_ip_address = true
  min                         = "1"
  max                         = "5"
}

resource "aws_security_group" "terminator" {
  name        = "terminator"
  description = "Allow all outbound and inbound SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terminator"
  }
}

data "template_file" "script" {
  template = file("templates/boot.sh.tpl")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.script.rendered
  }
}

