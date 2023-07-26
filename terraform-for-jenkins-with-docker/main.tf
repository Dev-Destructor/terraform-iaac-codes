terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins-key-pair" {
  key_name   = "jenkins-key-pair.pem"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "jenkins-key-pair.pem"
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Allow SSH"
  vpc_id      = "vpc-04bdcfbb9286ed26d"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = "ami-0f5ee92e2d63afc18"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.jenkins-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data              = file("installation.sh")
  tags = {
    Name = "jenkins"
  }
}
