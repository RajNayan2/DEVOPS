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

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "website" {
  bucket = "terraform-q4-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"

  tags = {
    Name = "Terraform-Q4-Website"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"

  source       = "${path.module}/index.html"
  content_type = "text/html"
}

output "bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
