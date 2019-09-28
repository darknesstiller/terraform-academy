// Configure AWS Cloud provider
provider "aws" {
  region = var.aws_region
}

# If you prefer, you can store the Terraform state in S3
# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    region = "us-west-2"
  }
}

#--------------------------------------------------------------
# default VPC
# https://www.terraform.io/docs/providers/aws/r/default_vpc.html
#--------------------------------------------------------------
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


resource "aws_elb" "elb" {
  name            = "sample-app-elb-dev"
  subnets         = data.aws_subnet_ids.vpc_subnets.ids
  security_groups = [aws_security_group.web.id]
  tags = merge(
    var.tags,
    {
      "Name" = format("%s", "sample-app-elb-server")
    }
  )
  listener {
    instance_port     = "80"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }
  health_check {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 100
  internal                    = false
}

# resource "aws_route53_zone" "limalymon" {
#   name = var.domain
# }

resource "aws_route53_record" "dns_web" {
  zone_id = data.aws_route53_zone.current.zone_id
  name    = "my-lb-example.limalymon.click"
  type    = "A"
  alias {
    name                   = aws_elb.elb.dns_name
    zone_id                = aws_elb.elb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web"
  description = "Allow web traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "lc" {
  name_prefix                 = "sample-app-dev-lc-latest"
  image_id                    = "ami-000b133338f7f4255"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.web.id]
  user_data                   = data.template_file.deploy_sh.rendered
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix               = "sample-app-dev-asg-latest"
  launch_configuration      = aws_launch_configuration.lc.name
  load_balancers            = [aws_elb.elb.id]
  health_check_type         = "ELB"
  health_check_grace_period = 60
  default_cooldown          = 60
  min_size                  = 1
  max_size                  = 1
  wait_for_elb_capacity     = 1
  desired_capacity          = 1
  vpc_zone_identifier       = data.aws_subnet_ids.vpc_subnets.ids

  tags = [
    {
      "key" = "Name"
      "value" = "sample-app-dev-ec2-latest"
      "propagate_at_launch" = true
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

