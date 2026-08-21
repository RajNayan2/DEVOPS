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

variable "ami_id" {
  type    = string
  default = "ami-0aa761682283b4cc8"
}

variable "key_name" {
  type    = string
  default = "q3-key"
}

variable "private_key_path" {
  type    = string
  default = "/home/raj-nayan/q3-key.pem"
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

resource "aws_security_group" "nginx" {
  name        = "terraform-q6-nginx-sg"
  description = "SSH and HTTP for Q6"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Q6-Nginx-SG"
  }
}

resource "aws_instance" "nginx" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.nginx.id
  ]

  tags = {
    Name = "Terraform-Q6-Nginx"
  }

  provisioner "file" {
    source      = "${path.module}/provisioners.sh"
    destination = "/home/ubuntu/provisioners.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/provisioners.sh",
      "sudo /home/ubuntu/provisioners.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

output "instance_id" {
  value = aws_instance.nginx.id
}

output "public_ip" {
  value = aws_instance.nginx.public_ip
}
