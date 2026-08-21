output "instance_public_ip" {
  description = "Public IP address of EC2"
  value       = aws_instance.server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of EC2"
  value       = aws_instance.server.private_ip
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.bucket.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.bucket.bucket
}

output "instance_id" {
  value = aws_instance.server.id
}
