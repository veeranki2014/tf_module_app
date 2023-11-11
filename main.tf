

## Route53 (DNS)
#resource "aws_route53_record" "main" {
#  zone_id                   = "Z05332201VBHF9VM3Q9N5"
#  name                      = "${var.component}-dev"
#  type                      = "A"
#  ttl                       = 30
#  records                   = [aws_instance.instance.private_ip]
#}


# Security Groups
resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.sg_subnets_cidr

  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allow_prometheus_cidr

  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_cidr

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

### ALB Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.component}-${var.env}-tg"
  deregistration_delay = 30
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check{
    enabled               = true
    interval              = 5
    path                  = "/health"
    port                  = var.app_port
    protocol              = "HTTP"
    timeout               = 4
    healthy_threshold     = 2
    unhealthy_threshold   = 2
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.listener_arn
  priority     = var.lb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.env}.veerankitek.com"]
    }
  }
}

### Launch_template for Auto Scaling Group ####
resource "aws_launch_template" "main" {
  name                      = "${var.component}-${var.env}"

  iam_instance_profile {
    name                    = aws_iam_instance_profile.instance_profile.name
  }
  image_id                  = data.aws_ami.main.id
  instance_type             = var.instance_type
  vpc_security_group_ids    = [ aws_security_group.main.id ]

  tag_specifications {
    resource_type           = "instance"
    tags                    = merge ({ Name = "${var.component}-${var.env}", Monitor = "yes"}, var.tags )
  }

  user_data                 = base64encode(templatefile("${path.module}/userdata.sh", {
    env                     = var.env
    component               = var.component
    #hostnames   = {"dev":"devhost","test":"testhost","prod":"prodhost"}
  }))

#  block_device_mappings {
#    device_name = "/dev/sda1"
#
#    ebs {
#      volume_size = 10
#      encrypted = "true"
#      kms_key_id = var.kms_key_id
#    }
#  }
}

resource "aws_autoscaling_group" "main" {
  #availability_zones = ["us-east-1a"] ##we provide the subnet Group
  vpc_zone_identifier = var.subnets_ids
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = [aws_lb_target_group.main.arn]


  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}

## Route53 (DNS)
resource "aws_route53_record" "main" {
  zone_id                   = "Z05332201VBHF9VM3Q9N5"
  name                      = "${var.component}-${var.env}"
  type                      = "CNAME"
  ttl                       = 30
  records                   = [ var.lb_dns_name]
}










## EC2
#resource "aws_instance" "instance" {
#  instance_type          = "t2.micro"
#  ami                    = data.aws_ami.main.id
#  vpc_security_group_ids = [aws_security_group.main.id]
#  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
#
#  tags = merge ({
#    Name = "${var.component}-${var.env}-ec2"
#    },
#    var.tags )
#}
## null_resource for Ansible
#resource "null_resource" "ansible" {
#  depends_on = [aws_instance.instance, aws_route53_record.main]
#  provisioner "remote-exec" {
#    connection {
#      type                = "ssh"
#      user                = "centos"
#      password            = "DevOps321"
#      host                = aws_instance.instance.public_ip
#    }
#    inline                = [
#      "sudo labauto ansible",
#      "sudo set-host -skip-apply ${var.component}",
#      "ansible-pull -i localhost, -U https://github.com/veeranki2014/roboshop_ansible main.yml -e env=${var.env} -e role_name=${var.component}"
#    ]
#  }
#}




