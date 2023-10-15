terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.56.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

// VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "prod-vpc"
  }
}

// Subnets
resource "aws_subnet" "public_subnet_01" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.public_subnet_01_cidr

  tags = {
    Name = "prod_public_subnet_01"
  }
}

resource "aws_subnet" "public_subnet_02" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.public_subnet_02_cidr

  tags = {
    Name = "prod_public_subnet_02"
  }
}

resource "aws_subnet" "private_subnet_01" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.private_subnet_01_cidr

  tags = {
    Name = "prod_private_subnet_01"
  }
}

resource "aws_subnet" "private_subnet_02" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.private_subnet_02_cidr

  tags = {
    Name = "prod_private_subnet_02"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "prod_gateway" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod_internet_gateway"
  }
}

// Elastic IP
resource "aws_eip" "eip_subnet_1" {}

resource "aws_eip" "eip_subnet_2" {}

// NAT Gateway
resource "aws_nat_gateway" "nat_gateway_subnet_1" {
  allocation_id = aws_eip.eip_subnet_1.id
  subnet_id     = aws_subnet.public_subnet_01.id

  tags = {
    Name = "prod_nat_gateway_subnet_1"
  }
}

resource "aws_nat_gateway" "nat_gateway_subnet_2" {
  allocation_id = aws_eip.eip_subnet_2.id
  subnet_id     = aws_subnet.public_subnet_02.id

  tags = {
    Name = "prod_nat_gateway_subnet_2"
  }
}

// Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_gateway.id
  }

  tags = {
    Name = "prod_public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_subnet_1.id
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_subnet_2.id
  }

  tags = {
    Name = "prod_private_route_table"
  }
}

// Route Table Association
resource "aws_route_table_association" "public_route_table_association_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_02.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_02.id
  route_table_id = aws_route_table.private_route_table.id
}
