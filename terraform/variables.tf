variable "aws_region" {
  default = "ap-south-1"
}

variable "project_name" {
  default = "elt-cloud"
}

variable "s3_bucket_name" {
  description = "Must be globally unique — add your name or number"
  default     = "elt-cloud-raw-srikrishna"
}

variable "ec2_ami" {
  description = "Ubuntu 22.04 LTS — ap-south-1"
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "ec2_instance_type" {
  default = "t3.micro"
}

variable "key_pair_name" {
  description = "Your EC2 key pair name (created in next step)"
  default     = "elt-cloud-key"
}
