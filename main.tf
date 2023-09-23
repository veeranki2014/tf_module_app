## IAM Policy
#resource "aws_iam_policy" "policy" {
#  name        = "${var.component}-${var.env}-ssm-pm-policy"
#  path        = "/"
#  description = "${var.component}-${var.env}-ssm-pm-policy"
#
#  policy = jsonencode({
#    "Version": "2012-10-17",
#    "Statement": [
#      {
#        "Sid": "VisualEditor0",
#        "Effect": "Allow",
#        "Action": [
#          "ssm:GetParameterHistory",
#          "ssm:GetParametersByPath",
#          "ssm:GetParameters",
#          "ssm:GetParameter"
#        ],
#        "Resource": "arn:aws:ssm:us-east-1:155405255921:parameter/roboshop.${var.env}.${var.component}.*"
#      }
#    ]
#  })
#}
## IAM Role
#resource "aws_iam_role" "role" {
#  name = "${var.component}-${var.env}-ec2-role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Sid    = ""
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      },
#    ]
#  })
#
#  tags = {
#    tag-key = "${var.component}-${var.env}-ec2-role"
#  }
#}
#
##Instance Profile
#resource "aws_iam_instance_profile" "instance_profile" {
#  name = "${var.component}-${var.env}-ec2-role"
#  role = aws_iam_role.role.name
#}
#
##IAM Role Policy Attachement
#resource "aws_iam_role_policy_attachment" "policy-attach" {
#  role       = aws_iam_role.role.name
#  policy_arn = aws_iam_policy.policy.arn
#}
## Route53 (DNS)
#resource "aws_route53_record" "main" {
#  zone_id                   = "Z05332201VBHF9VM3Q9N5"
#  name                      = "${var.component}-dev"
#  type                      = "A"
#  ttl                       = 30
#  records                   = [aws_instance.instance.private_ip]
#}
## Security Groups
#resource "aws_security_group" "main" {
#  name        = "${var.component}-${var.env}-sg"
#  description = "${var.component}-${var.env}-sg"
#
#  ingress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "${var.component}-${var.env}-sg"
#  }
#}
#
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

# Security Groups for testing purpose
resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

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

resource "aws_instance" "test" {
  ami                       = data.aws_ami.main.id
  instance_type             = "t3.micro"
  vpc_security_group_ids    = [aws_security_group.main.id]
  subnet_id                 = var.subnet_id

  tags = {
    Name = var.component
  }
}
