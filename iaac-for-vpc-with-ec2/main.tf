terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# provider
provider "aws" {
  region  = var.region
  profile = var.profile
}

# VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-prod-vpc"
  }

  enable_dns_hostnames = true
}

# Public Subnet
resource "aws_subnet" "public-subnet" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }

  map_public_ip_on_launch = true
}

# Private Subnet
resource "aws_subnet" "private-subnet" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.prod-vpc
  ]

  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# Route table with target as Internet Gateway
resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

# Elastic IP
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public-subnet,
    aws_eip.elastic_ip,
  ]
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "nat-gateway"
  }
}

# Route Table with target as NAT Gateway
resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "NAT-route-table"
  }
}

# Associate Route Table to Private Subnet
resource "aws_route_table_association" "associate_route_table_to_private_subnet" {
  depends_on = [
    aws_subnet.private-subnet,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.NAT_route_table.id
}

# Security Group for the Bastion Host
resource "aws_security_group" "sg_bastion_host" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg bastion host"
  description = "bastion host security group"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host" {
  depends_on = [
    aws_security_group.sg_bastion_host,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
  subnet_id              = aws_subnet.public-subnet.id
  tags = {
    Name = "bastion host"
  }
}

# Key Pair Generation
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key-pair" {
  key_name   = var.key-pair
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = var.key-pair
}

# Security Group for the Private EC2 Instance
resource "aws_security_group" "sg_private_instance" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg private instance"
  description = "private instance security group"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.sg_bastion_host.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private EC2 Instance
resource "aws_instance" "servers" {
  depends_on             = [aws_security_group.sg_private_instance]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_private_instance.id]
  subnet_id              = aws_subnet.private-subnet.id

  tags = {
    Name = "private instance"
  }
}

# Launch Configuration for the Private EC2 Instance
resource "aws_launch_configuration" "private_instance_launch_configuration" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.private-subnet,
    aws_security_group.sg_private_instance,
  ]
  name_prefix                 = "private-instance-launch-configuration"
  image_id                    = var.ami_map[var.region]
  instance_type               = var.instance
  security_groups             = [aws_security_group.sg_private_instance.id]
  associate_public_ip_address = false
  key_name                    = var.key-pair
  user_data                   = file("./user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for the private EC2 instances
resource "aws_autoscaling_group" "private_instance_autoscaling_group" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.private-subnet,
    aws_security_group.sg_private_instance,
  ]
  name                      = "private-instance-autoscaling-group"
  max_size                  = var.auto-scale-max-size
  min_size                  = var.auto-scale-min-size
  desired_capacity          = var.auto-scale-min-size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.private_instance_launch_configuration.name
  vpc_zone_identifier       = [aws_subnet.private-subnet.id]

  tag {
    key                 = "Name"
    value               = "private-instance-autoscaling-group"
    propagate_at_launch = true
  }
}

# Security Group for the Public EC2 Instance
resource "aws_security_group" "sg_public_instance" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg public instance"
  description = "public instance security group"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTP"
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
}

# Public EC2 Instance
resource "aws_instance" "public_instance" {
  depends_on             = [aws_security_group.sg_public_instance]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_public_instance.id]
  subnet_id              = aws_subnet.public-subnet.id

  tags = {
    Name = "public instance"
  }
}

# Launch Configuration for the Public EC2 Instance
resource "aws_launch_configuration" "public_instance_launch_configuration" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet,
    aws_security_group.sg_public_instance,
  ]
  name_prefix                 = "public-instance-launch-configuration"
  image_id                    = var.ami_map[var.region]
  instance_type               = var.instance
  security_groups             = [aws_security_group.sg_public_instance.id]
  associate_public_ip_address = true
  key_name                    = var.key-pair
  user_data                   = file("./user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for the public EC2 instances
resource "aws_autoscaling_group" "public_instance_autoscaling_group" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet,
    aws_security_group.sg_public_instance,
  ]
  name                      = "public-instance-autoscaling-group"
  max_size                  = var.auto-scale-max-size
  min_size                  = var.auto-scale-min-size
  desired_capacity          = var.auto-scale-min-size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.public_instance_launch_configuration.name
  vpc_zone_identifier       = [aws_subnet.public-subnet.id]

  tag {
    key                 = "Name"
    value               = "public-instance-autoscaling-group"
    propagate_at_launch = true
  }
}

# Target Group for the Public EC2 Instance
resource "aws_lb_target_group" "public_instance_target_group" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet,
  ]
  name     = "public-instance-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod-vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "public-instance-target-group"
  }
}

# Load Balancer for the Public EC2 Instance
resource "aws_lb" "public_instance_load_balancer" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet,
    aws_lb_target_group.public_instance_target_group,
  ]
  name               = "public-instance-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_public_instance.id]
  subnets            = [aws_subnet.public-subnet.id]

  tags = {
    Name = "public-instance-load-balancer"
  }
}

# Listener for the Public EC2 Instance
resource "aws_lb_listener" "public_instance_listener" {
  depends_on = [
    aws_lb.public_instance_load_balancer,
    aws_lb_target_group.public_instance_target_group,
  ]
  load_balancer_arn = aws_lb.public_instance_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.public_instance_target_group.arn
    type             = "forward"
  }
}
