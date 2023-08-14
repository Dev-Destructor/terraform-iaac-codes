output "bastion-host-az1-public-ip" {
  value = aws_instance.bastion_host_az1.public_ip
}

output "bastion-host-az2-public-ip" {
  value = aws_instance.bastion_host_az2.public_ip
}

output "public_load_balancer_dns_name" {
  value = aws_lb.load_balancer_public_subnet.dns_name
}

output "private_load_balancer_dns_name" {
  value = aws_lb.load_balancer_private_subnet.dns_name
}

