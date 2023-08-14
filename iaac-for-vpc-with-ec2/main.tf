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

# Public Subnets
resource "aws_subnet" "public-subnet-az1" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet-az1"
  }

  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-subnet-az2" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "public-subnet-az2"
  }

  map_public_ip_on_launch = true
}

# Private Subnets
resource "aws_subnet" "private-subnet-az1" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-subnet-az1"
  }
}

resource "aws_subnet" "private-subnet-az2" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet-az2"
  }
}

resource "aws_subnet" "db-subnet-az1" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.4.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "db-subnet-az1"
  }
}

resource "aws_subnet" "db-subnet-az2" {
  depends_on = [aws_vpc.prod-vpc]

  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "192.168.5.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "db-subnet-az2"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "db-subnet-group" {
  name = "db-subnet-group"
  subnet_ids = [
    aws_subnet.db-subnet-az1.id,
    aws_subnet.db-subnet-az2.id
  ]
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

# Elastic IP
resource "aws_eip" "elastic_ip_az1" {
  domain = "vpc"
}

resource "aws_eip" "elastic_ip_az2" {
  domain = "vpc"
}

resource "aws_eip" "elastic_ip_db_az1" {
  domain = "vpc"
}

resource "aws_eip" "elastic_ip_db_az2" {
  domain = "vpc"
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway_az1" {
  depends_on = [
    aws_eip.elastic_ip_az1,
    aws_subnet.public-subnet-az1
  ]

  allocation_id = aws_eip.elastic_ip_az1.id
  subnet_id     = aws_subnet.private-subnet-az1.id

  tags = {
    Name = "nat-gateway-az1"
  }
}

resource "aws_nat_gateway" "nat_gateway_az2" {
  depends_on = [
    aws_eip.elastic_ip_az2,
    aws_subnet.public-subnet-az2
  ]

  allocation_id = aws_eip.elastic_ip_az2.id
  subnet_id     = aws_subnet.private-subnet-az2.id

  tags = {
    Name = "nat-gateway-az2"
  }
}

resource "aws_nat_gateway" "nat_gateway_db_az1" {
  depends_on = [
    aws_eip.elastic_ip_db_az1,
    aws_subnet.public-subnet-az1
  ]

  allocation_id = aws_eip.elastic_ip_db_az1.id
  subnet_id     = aws_subnet.db-subnet-az1.id

  tags = {
    Name = "nat-gateway-db-az1"
  }
}

resource "aws_nat_gateway" "nat_gateway_db_az2" {
  depends_on = [
    aws_eip.elastic_ip_db_az2,
    aws_subnet.public-subnet-az2
  ]

  allocation_id = aws_eip.elastic_ip_db_az2.id
  subnet_id     = aws_subnet.db-subnet-az2.id

  tags = {
    Name = "nat-gateway-db-az2"
  }
}

# Route table for public subnets
resource "aws_route_table" "route_table_public_subnets" {
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
    Name = "route-table-public-subnets"
  }
}

resource "aws_route_table_association" "associate_route_table_to_public_subnet_az1" {
  depends_on = [
    aws_subnet.public-subnet-az1,
    aws_route_table.route_table_public_subnets,
  ]
  subnet_id      = aws_subnet.public-subnet-az1.id
  route_table_id = aws_route_table.route_table_public_subnets.id
}

resource "aws_route_table_association" "associate_route_table_to_public_subnet_az2" {
  depends_on = [
    aws_subnet.public-subnet-az1,
    aws_route_table.route_table_public_subnets,
  ]
  subnet_id      = aws_subnet.public-subnet-az2.id
  route_table_id = aws_route_table.route_table_public_subnets.id
}

# Route Table for private subnets
resource "aws_route_table" "route_table_private_subnets" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_nat_gateway.nat_gateway_az1,
    aws_nat_gateway.nat_gateway_az2,
  ]

  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "192.168.2.0/24"
    gateway_id = aws_nat_gateway.nat_gateway_az1.id
  }

  route {
    cidr_block = "192.168.3.0/24"
    gateway_id = aws_nat_gateway.nat_gateway_az2.id
  }

  tags = {
    Name = "route-table-private-subnets"
  }
}

resource "aws_route_table_association" "associate_route_table_to_private_subnet_az1" {
  depends_on = [
    aws_subnet.private-subnet-az1,
    aws_route_table.route_table_private_subnets,
  ]
  subnet_id      = aws_subnet.private-subnet-az1.id
  route_table_id = aws_route_table.route_table_private_subnets.id
}

resource "aws_route_table_association" "associate_route_table_to_private_subnet_az2" {
  depends_on = [
    aws_subnet.private-subnet-az2,
    aws_route_table.route_table_private_subnets,
  ]
  subnet_id      = aws_subnet.private-subnet-az2.id
  route_table_id = aws_route_table.route_table_private_subnets.id
}

# Route Table for DB subnets
resource "aws_route_table" "route_table_db_subnets" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_nat_gateway.nat_gateway_db_az1,
    aws_nat_gateway.nat_gateway_db_az2,
  ]

  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "192.168.4.0/24"
    gateway_id = aws_nat_gateway.nat_gateway_db_az1.id
  }

  route {
    cidr_block = "192.168.5.0/24"
    gateway_id = aws_nat_gateway.nat_gateway_db_az2.id
  }

  tags = {
    Name = "route-table-db-subnets"
  }
}

resource "aws_route_table_association" "associate_route_table_to_db_subnet_az1" {
  depends_on = [
    aws_subnet.db-subnet-az1,
    aws_route_table.route_table_db_subnets,
  ]
  subnet_id      = aws_subnet.db-subnet-az1.id
  route_table_id = aws_route_table.route_table_db_subnets.id
}

resource "aws_route_table_association" "associate_route_table_to_db_subnet_az2" {
  depends_on = [
    aws_subnet.db-subnet-az2,
    aws_route_table.route_table_db_subnets,
  ]
  subnet_id      = aws_subnet.db-subnet-az2.id
  route_table_id = aws_route_table.route_table_db_subnets.id
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
    cidr_blocks = [var.user_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host_az1" {
  depends_on = [
    aws_security_group.sg_bastion_host,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
  subnet_id              = aws_subnet.public-subnet-az1.id
  tags = {
    Name = "Bastion Host AZ1"
  }
}

resource "aws_instance" "bastion_host_az2" {
  depends_on = [
    aws_security_group.sg_bastion_host,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_bastion_host.id]
  subnet_id              = aws_subnet.public-subnet-az2.id
  tags = {
    Name = "Bastion Host AZ2"
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
    security_groups = [
      aws_security_group.sg_bastion_host.id
    ]
  }

  ingress {
    description     = "allow HTTP"
    from_port       = var.public_instance_listening_port
    to_port         = var.public_instance_listening_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_load_balancer.id]
  }
}

# Launch Configuration for the Public EC2 Instance
resource "aws_launch_template" "public_instance_launch_template" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_security_group.sg_public_instance,
  ]
  name_prefix   = "public-instance-launch-template"
  image_id      = var.ami_map[var.region]
  instance_type = var.instance
  key_name      = var.key-pair
  user_data     = base64encode(file("./user_data/public.sh"))

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_public_instance.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for the public EC2 instances
resource "aws_autoscaling_group" "public_instance_autoscaling_group" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet-az1,
    aws_subnet.public-subnet-az2,
    aws_security_group.sg_public_instance,
  ]
  name                      = "public-instance-autoscaling-group"
  max_size                  = var.auto-scale-max-size
  min_size                  = var.auto-scale-min-size
  desired_capacity          = var.auto-scale-min-size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.public_instance_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public-subnet-az1.id, aws_subnet.public-subnet-az2.id]

  tag {
    key                 = "Name"
    value               = "public-instance-autoscaling-group"
    propagate_at_launch = true
  }
}

# Target Group for the Public EC2 Instance
resource "aws_lb_target_group" "public_instance_target_group" {
  depends_on = [
    aws_vpc.prod-vpc
  ]
  name     = "public-instance-target-group"
  port     = 3000
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

# Security Group for the Private EC2 Instance
resource "aws_security_group" "sg_private_instance" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg private instance"
  description = "private instance security group"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description     = "allow HTTP"
    from_port       = var.private_instance_listening_port
    to_port         = var.private_instance_listening_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_load_balancer.id]
  }

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

# Launch Template for the Private EC2 Instance
resource "aws_launch_template" "private_instance_launch_template" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_security_group.sg_private_instance,
  ]
  name_prefix   = "private-instance-launch-template"
  image_id      = var.ami_map[var.region]
  instance_type = var.instance
  key_name      = var.key-pair
  user_data     = base64encode(file("./user_data/private.sh"))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg_private_instance.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for the Private EC2 Instance
resource "aws_autoscaling_group" "private_instance_autoscaling_group" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.private-subnet-az1,
    aws_subnet.private-subnet-az2,
    aws_security_group.sg_private_instance,
  ]
  name                      = "private-instance-autoscaling-group"
  max_size                  = var.auto-scale-max-size
  min_size                  = var.auto-scale-min-size
  desired_capacity          = var.auto-scale-min-size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.private_instance_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.private-subnet-az1.id, aws_subnet.private-subnet-az2.id]

  tag {
    key                 = "Name"
    value               = "private-instance-autoscaling-group"
    propagate_at_launch = true
  }
}

# Target Group for the Private EC2 Instance
resource "aws_lb_target_group" "private_instance_target_group" {
  depends_on = [
    aws_vpc.prod-vpc
  ]
  name     = "private-instance-target-group"
  port     = 9000
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
    Name = "private-instance-target-group"
  }
}

# Security Group for DB Instances
resource "aws_security_group" "sg_db_instance" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg db instance"
  description = "db instance security group"
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

  ingress {
    description = "allow MySQL"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [
      aws_security_group.sg_private_instance.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Public EC2 Instances
resource "aws_instance" "public_instance_az1" {
  depends_on = [
    aws_autoscaling_group.public_instance_autoscaling_group,
    aws_lb_target_group.public_instance_target_group,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_public_instance.id]
  subnet_id              = aws_subnet.public-subnet-az1.id
  tags = {
    Name = "Public Instance AZ1"
  }
}

resource "aws_instance" "public_instance_az2" {
  depends_on = [
    aws_autoscaling_group.public_instance_autoscaling_group,
    aws_lb_target_group.public_instance_target_group,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_public_instance.id]
  subnet_id              = aws_subnet.public-subnet-az2.id
  tags = {
    Name = "Public Instance AZ2"
  }
}

# Private EC2 Instances
resource "aws_instance" "private_instance_az1" {
  depends_on = [
    aws_autoscaling_group.private_instance_autoscaling_group,
    aws_lb_target_group.private_instance_target_group,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_private_instance.id]
  subnet_id              = aws_subnet.private-subnet-az1.id
  tags = {
    Name = "Private Instance AZ1"
  }
}

resource "aws_instance" "private_instance_az2" {
  depends_on = [
    aws_autoscaling_group.private_instance_autoscaling_group,
    aws_lb_target_group.private_instance_target_group,
  ]
  ami                    = var.ami_map[var.region]
  instance_type          = var.instance
  key_name               = var.key-pair
  vpc_security_group_ids = [aws_security_group.sg_private_instance.id]
  subnet_id              = aws_subnet.private-subnet-az2.id
  tags = {
    Name = "Private Instance AZ2"
  }
}

# DB Instances
resource "aws_db_instance" "postgres_db_multiaz" {
  allocated_storage           = 10
  engine                      = "postgres"
  engine_version              = "15.3"
  db_name                     = "postgres_db"
  instance_class              = "db.m5d.large"
  manage_master_user_password = true
  username                    = "postgres"
  db_subnet_group_name        = aws_db_subnet_group.db-subnet-group.name
  vpc_security_group_ids      = [aws_security_group.sg_db_instance.id]
  multi_az                    = true
  skip_final_snapshot         = true
}

# Security Group for the Load Balancer
resource "aws_security_group" "sg_load_balancer" {
  depends_on = [
    aws_vpc.prod-vpc,
  ]
  name        = "sg load balancer"
  description = "load balancer security group"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "allow HTTP"
    from_port   = var.private_instance_listening_port
    to_port     = var.private_instance_listening_port
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

# Load Balancer for the Public EC2 Instance
resource "aws_lb" "load_balancer_public_subnet" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.public-subnet-az1,
    aws_subnet.public-subnet-az2,
    aws_lb_target_group.public_instance_target_group,
  ]
  name               = "load-balancer-public-subnet"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_load_balancer.id]
  subnets            = [aws_subnet.public-subnet-az1.id, aws_subnet.public-subnet-az2.id]

  tags = {
    Name = "load-balancer"
  }
}

# Listener for the Public EC2 Instance
resource "aws_lb_listener" "public_instance_listener" {
  depends_on = [
    aws_lb.load_balancer_public_subnet,
    aws_lb_target_group.public_instance_target_group,
  ]
  load_balancer_arn = aws_lb.load_balancer_public_subnet.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.public_instance_target_group.arn
    type             = "forward"
  }
}

# Load Balancer for the Private EC2 Instance
resource "aws_lb" "load_balancer_private_subnet" {
  depends_on = [
    aws_vpc.prod-vpc,
    aws_subnet.private-subnet-az1,
    aws_subnet.private-subnet-az2,
    aws_lb_target_group.private_instance_target_group,
  ]
  name               = "load-balancer-private-subnet"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_load_balancer.id]
  subnets            = [aws_subnet.private-subnet-az1.id, aws_subnet.private-subnet-az2.id]

  tags = {
    Name = "load-balancer"
  }
}

# Listener for the Private EC2 Instance
resource "aws_lb_listener" "private_instance_listener" {
  depends_on = [
    aws_lb.load_balancer_private_subnet,
    aws_lb_target_group.private_instance_target_group,
  ]
  load_balancer_arn = aws_lb.load_balancer_private_subnet.arn
  port              = 9000
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.private_instance_target_group.arn
    type             = "forward"
  }
}
