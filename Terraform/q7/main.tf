terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.57"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "q7" {
  name        = "terraform-q7-sg"
  description = "SSH access for Q7"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.q7.id
  ]

  tags = {
    Name = "Terraform-Q7-EC2"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"

  tags = {
    Name = "Terraform-Q7-S3"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}
