variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID (used for DynamoDB ARN)"
}

variable "state_bucket_name" {
  type        = string
  description = "Existing S3 bucket for Terraform state"
}

variable "lock_table_name" {
  type        = string
  description = "Existing DynamoDB table for state locking"
  default     = "terraform-locks"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH (e.g., your office IP /32)"
}

variable "ssh_key_name" {
  type        = string
  description = "Name for the AWS Key Pair"
  default     = "gh-runner-key"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to your SSH public key (e.g., ~/.ssh/id_rsa.pub)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for runner"
  default     = "t3.small"
}
