data "aws_ami" "main"{
  owners                    = ["973714476881"]
  name_regex                = "Centos-8-DevOps-Practice"
  most_recent               = true
}