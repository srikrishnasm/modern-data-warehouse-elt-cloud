provider "aws" {
  region = var.aws_region
}

# S3 bucket — raw zone
resource "aws_s3_bucket" "raw" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Project     = var.project_name
    Layer       = "raw"
  }
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role — lets EC2 access S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "${var.project_name}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Security group — allow SSH + Airflow UI
resource "aws_security_group" "airflow_sg" {
  name        = "${var.project_name}-airflow-sg"
  description = "Allow SSH and Airflow UI"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Airflow UI"
    from_port   = 8080
    to_port     = 8080
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
    Project = var.project_name
  }
}

# EC2 instance — Airflow
resource "aws_instance" "airflow" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.airflow_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name    = "${var.project_name}-airflow"
    Project = var.project_name
  }
}
