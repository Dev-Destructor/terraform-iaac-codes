output "aws_vpc_id" {
  description = "The VPC Id"
  value       = aws_vpc.prod-vpc.id
}

output "aws_vpc_public_subnets" {
  description = "The VPC public subnets"
  value       = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
}

output "aws_vpc_private_subnets" {
  description = "Subnets IDs in the VPC"
  value       = [aws_subnet.private_subnet_01.id, aws_subnet.private_subnet_02.id]
}
