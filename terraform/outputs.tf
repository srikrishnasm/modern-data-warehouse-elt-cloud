output "ec2_public_ip" {
  description = "SSH into this IP"
  value       = aws_instance.airflow.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.airflow.public_dns
}

output "s3_bucket_name" {
  description = "Raw data bucket"
  value       = aws_s3_bucket.raw.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.raw.arn
}
