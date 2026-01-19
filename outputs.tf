# Output Variables

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.myapp_instance.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.myapp_instance.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.myapp_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.myapp_subnet.id
}
