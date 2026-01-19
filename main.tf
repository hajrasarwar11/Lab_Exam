# Provider Configuration
# The AWS provider will read credentials from:
# - ~/.aws/credentials (for access keys)
# - ~/.aws/config (for region and other settings)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  # Uses default profile from ~/.aws/credentials and ~/.aws/config
  # You can specify a different profile by uncommenting the line below:
  # profile = "your-profile-name"
  
  # Region will be read from ~/.aws/config or can be specified here:
  # region = "us-east-1"
}

# Data source to get the current public IP address
data "http" "my_ip" {
  url = "https://icanhazip.com"
}

# Locals block to format the IP address with /32 CIDR notation
locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

# VPC Resource
resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# Subnet Resource
resource "aws_subnet" "myapp_subnet" {
  vpc_id            = aws_vpc.myapp_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# Default Route Table Configuration
resource "aws_default_route_table" "myapp_default_rt" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rt"
  }
}

# Default Security Group Configuration
resource "aws_default_security_group" "myapp_default_sg" {
  vpc_id = aws_vpc.myapp_vpc.id

  # Ingress rule for SSH (TCP 22) from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # Ingress rule for HTTP (TCP 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for HTTPS (TCP 443) from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule for all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

# AWS Key Pair for SSH access
resource "aws_key_pair" "serverkey" {
  key_name   = "serverkey"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

# EC2 Instance Resource
resource "aws_instance" "myapp_instance" {
  # Amazon Linux 2023 AMI (hard-coded)
  ami                    = "ami-003e2aaab8af13bc1"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.myapp_subnet.id
  vpc_security_group_ids = [aws_default_security_group.myapp_default_sg.id]
  availability_zone      = var.availability_zone
  associate_public_ip_address = true
  key_name               = aws_key_pair.serverkey.key_name
  
  # User data script for instance initialization
  user_data = file("${path.module}/entry-script.sh")

  tags = {
    Name = "${var.env_prefix}-ec2-instance"
  }

  depends_on = [
    aws_internet_gateway.myapp_igw
  ]
}
