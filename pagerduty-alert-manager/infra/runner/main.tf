terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.54"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
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

# Security Group for the runner
resource "aws_security_group" "runner_sg" {
  name        = "gh-runner-sg"
  description = "Allow SSH from trusted CIDR and all egress"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gh-runner-sg"
  }
}

# Key pair for SSH (public key provided by user)
resource "aws_key_pair" "runner_key" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

# IAM role for EC2 with S3/DynamoDB and SSM (optional) access
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner_role" {
  name               = "gh-runner-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Minimal policy for S3 state and DynamoDB locks + SSM for management
data "aws_iam_policy_document" "runner_policy_doc" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/*"
    ]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.lock_table_name}"]
  }

  statement {
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:SendCommand",
      "ssm:ListCommands",
      "ssm:ListCommandInvocations",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2messages:*",
      "ssmmessages:*",
      "cloudwatch:PutMetricData",
      "ec2:DescribeInstanceStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "runner_policy" {
  name   = "gh-runner-policy"
  policy = data.aws_iam_policy_document.runner_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_runner_policy" {
  role       = aws_iam_role.runner_role.name
  policy_arn = aws_iam_policy.runner_policy.arn
}

# Attach AWS managed SSM policy (optional, good for troubleshooting)
resource "aws_iam_role_policy_attachment" "attach_ssm_managed" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "gh-runner-profile"
  role = aws_iam_role.runner_role.name
}

# AMI (Amazon Linux 2023)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "runner" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.runner_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.runner_profile.name
  key_name               = aws_key_pair.runner_key.key_name

  tags = {
    Name = "github-actions-runner"
  }
}

output "runner_public_ip" {
  value = aws_instance.runner.public_ip
}

output "runner_instance_id" {
  value = aws_instance.runner.id
}
