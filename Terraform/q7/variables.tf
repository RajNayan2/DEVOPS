variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "ami_id" {
  type    = string
  default = "ami-0aa761682283b4cc8"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = "q3-key"
}

variable "bucket_prefix" {
  type    = string
  default = "terraform-q7"
}
