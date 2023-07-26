output "jenkins_instance_public_ip" {
  value = aws_instance.jenkins.public_ip
}
