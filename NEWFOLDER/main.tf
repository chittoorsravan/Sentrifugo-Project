provider "aws" {
  region = var.aws_region
}

# Creating Main VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Creating Public Subnet
resource "aws_subnet" "public_sub" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
}

# Creating IGW
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

# Creating Route_table and Association
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.main.id
}

# Creating Security Groups
resource "aws_security_group" "App_Sg" {
  name   = var.security_group_name
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_iam_role" "ecs_execution_role" {
  name = var.ecs_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "ECS_sentri" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "test" {
  family                   = "test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "sentrifugo",
    "image": "${var.container_image}",
    "cpu": ${var.task_cpu},
    "memory": ${var.task_memory},
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
TASK_DEFINITION
}

resource "aws_ecs_service" "sentrifugo_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ECS_sentri.id
  task_definition = aws_ecs_task_definition.test.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_sub.id]
    security_groups  = [aws_security_group.App_Sg.id]
    assign_public_ip = true
  }
}