terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.57"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "username" {
  type    = string
  default = "terraform-admin-user"
}

resource "aws_iam_user" "admin" {
  name = var.username

  tags = {
    Name = "Terraform IAM User"
  }
}

resource "aws_iam_user_policy_attachment" "administrator" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy_attachment" "ec2" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

output "username" {
  value = aws_iam_user.admin.name
}

output "user_arn" {
  value = aws_iam_user.admin.arn
}
