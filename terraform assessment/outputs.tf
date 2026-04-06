output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "web_server_private_ips" {
  description = "Private IPs of the web servers"
  value       = [aws_instance.web_1.private_ip, aws_instance.web_2.private_ip]
}

output "db_server_private_ip" {
  description = "Private IP of the database server"
  value       = aws_instance.db.private_ip
}