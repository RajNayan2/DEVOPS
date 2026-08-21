terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "key_name" {
  default = "q3-key"
}

variable "key_file" {
  default = "/home/raj-nayan/q3-key.pem"
}
data "aws_ssm_parameter" "ubuntu_2204" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
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

resource "aws_security_group" "q1_sg" {
  name        = "terraform-q1-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "q1" {
  ami           = data.aws_ssm_parameter.ubuntu_2204.value
  instance_type = "t3.micro"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.q1_sg.id
  ]

  key_name = var.key_name

  tags = {
    Name = "Terraform-Q1"
  }

  provisioner "file" {
    source      = "provisioners.sh"
    destination = "/home/ubuntu/provisioners.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.key_file)
      host        = self.public_ip
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
      private_key = file(var.key_file)
      host        = self.public_ip
    }
  }
}

output "public_ip" {
  value = aws_instance.q1.public_ip
}
