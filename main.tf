terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"  # Change this to your desired region
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sentrifugo-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"  # Change this to match your region
  map_public_ip_on_launch = true

  tags = {
    Name = "sentrifugo-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sentrifugo-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "sentrifugo-route-table"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "sentrifugo" {
  name        = "sentrifugo-sg"
  description = "Security group for Sentrifugo"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Name = "sentrifugo-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "sentrifugo" {
  ami           = "ami-04f7a54071e74f488"  
  instance_type = "t2.large"
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.sentrifugo.id]
  key_name              = "testing_saa02" 

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              dnf update -y

              # Install Docker
              dnf install -y docker
              systemctl start docker
              systemctl enable docker

              # Create directories for persistent data
              mkdir -p /sentrifugo/data
              mkdir -p /sentrifugo/logs

              # Install MariaDB
              docker run -d \
                --name mariadb \
                -e MYSQL_ROOT_PASSWORD=your_root_password \
                -e MYSQL_DATABASE=sentrifugo \
                -e MYSQL_USER=sentrifugo \
                -e MYSQL_PASSWORD=your_password \
                -v /sentrifugo/mysql:/var/lib/mysql \
                mariadb:10.5

              # Wait for MariaDB to be ready
              sleep 30

              # Run Sentrifugo
              docker run -d \
                --name sentrifugo \
                -p 80:80 \
                -v /sentrifugo/data:/var/www/html/public \
                -v /sentrifugo/logs:/var/www/html/logs \
                --link mariadb:mysql \
                gofaustino/sentrifugo
              EOF

  tags = {
    Name = "sentrifugo-server"
  }
}

# Output the public IP
output "public_ip" {
  value = aws_instance.sentrifugo.public_ip
}