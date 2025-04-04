output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_sub.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.App_Sg.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ECS_sentri.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.sentrifugo_service.name
}