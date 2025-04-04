variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-west-1a"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "Sentri_Sg"
}

variable "ecs_role_name" {
  description = "Name of the ECS execution role"
  type        = string
  default     = "ecs_execution_role"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "Sentrifugo_ECS"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "sentrifugo-service"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "gofaustino/sentrifugo"
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 2048
}

variable "service_desired_count" {
  description = "Desired number of tasks running"
  type        = number
  default     = 1
}