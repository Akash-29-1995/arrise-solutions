data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2023" {
  count = var.enable_ec2 && var.default_ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "default" {
  count = var.enable_ec2 && var.use_default_vpc ? 1 : 0

  default = true
}

data "aws_subnets" "default" {
  count = var.enable_ec2 && var.use_default_vpc && length(var.default_subnet_ids) == 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_security_group" "default" {
  count = var.enable_ec2 && var.use_default_vpc && length(var.default_security_group_ids) == 0 ? 1 : 0

  name   = "default"
  vpc_id = data.aws_vpc.default[0].id
}
