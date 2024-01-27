#!/bin/bash

project_dir="aws_infrastructure"
mkdir -p $project_dir

# VPC and Subnet Configuration
vpc_file="$project_dir/vpc.tf"
cat > $vpc_file <<EOF
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = false
  tags = {
    Name = "Subnet2"
  }
}
EOF

# ECS Cluster, Task Definition, and Service Configuration
ecs_file="$project_dir/ecs.tf"
cat > $ecs_file <<EOF
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/nginx"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ecr_read_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = var.nginx_container_port
    to_port     = var.nginx_container_port
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

resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  enable_deletion_protection = false
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_lb_target_group" "ecs_tg" {
  name     = "ecs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
  }
}

EOF

# RDS MySQL Instance Configuration
rds_file="$project_dir/rds.tf"
cat > $rds_file <<EOF
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = var.mysql_engine_version
  instance_class       = var.rds_instance_class
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "main" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  tags = {
    Name = "My DB Subnet Group"
  }
}

resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}
EOF

# Network Configuration
network_file="$project_dir/network.tf"
cat <<EOF > $network_file
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}
EOF

outputs_file="$project_dir/outputs.tf"

cat > $outputs_file <<EOF
output "vpc_id" {
  value = aws_vpc.main.id
}
output "subnet_ids" {
  value = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}
output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
output "rds_instance_address" {
  value = aws_db_instance.main.address
}
output "load_balancer_dns" {
  value = aws_lb.ecs_alb.dns_name
}
output "nginx_service_url" {
  value = "https://\${aws_lb.ecs_alb.dns_name}"
}
EOF

nat_file="$project_dir/nat.tf"
cat <<EOF > $nat_file
resource "aws_eip" "nat_eip" { 
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet1.id
  depends_on    = [aws_internet_gateway.main]
}
EOF

https_file="$project_dir/https.tf"
cat <<EOF > $https_file

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
EOF


nginx_file="$project_dir/nginx.tf"
cat <<EOF > $nginx_file
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = jsonencode([{
    name          = "nginx",
    image         = "533267130709.dkr.ecr.eu-west-1.amazonaws.com/nginx-commit:latest",
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/nginx"
        awslogs-region        = "eu-west-1"
        awslogs-stream-prefix = "ecs"
      }
    }
    environment = [
      { name = "DB_HOST", value = aws_db_instance.main.address },
      { name = "DB_USER", value = var.db_user },
      { name = "DB_PASSWORD", value = var.db_password },
      { name = "DB_NAME", value = var.db_name }
    ],
    portMappings  = [{
      containerPort = var.nginx_container_port,
      hostPort      = var.nginx_host_port
    }]
  }])
}

resource "aws_ecs_service" "nginx_service" {
  name             = var.nginx_service_name
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.nginx.arn
  launch_type      = "FARGATE"
  desired_count    = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "nginx"
    container_port   = var.nginx_container_port
  }

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  depends_on = [aws_lb_listener.https_listener]
}
EOF

# ECR Repository Configuration
ecr_file="$project_dir/ecr.tf"
cat <<EOF > $ecr_file
resource "aws_ecr_repository" "nginx_commit" {
  name = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "Nginx Commit Repository" }
}
EOF

# Additional Network Configuration for NACLs
nacl_file="$project_dir/nacl.tf"
cat <<EOF > $nacl_file
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "-1"
    rule_no     = 100
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }

  egress {
    protocol    = "-1"
    rule_no     = 100
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }

  tags = { Name = "PublicNACL" }
}

resource "aws_network_acl_association" "public_nacl_association" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.subnet1.id
}
EOF

# Variables Definition (Enhanced)
variables_file="$project_dir/variables.tf"
cat > $variables_file <<EOF
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet1_cidr" { default = "10.0.1.0/24" }
variable "subnet2_cidr" { default = "10.0.2.0/24" }
variable "availability_zone1" { default = "eu-west-1a" }
variable "availability_zone2" { default = "eu-west-1b" }
variable "ecs_cluster_name" { default = "main-cluster" }
variable "nginx_task_family" { default = "nginx" }
variable "nginx_cpu" { default = "256" }
variable "nginx_memory" { default = "512" }
variable "nginx_image" { default = "nginx:latest" }
variable "nginx_container_port" { default = 80 }
variable "nginx_host_port" { default = 80 }
variable "nginx_service_name" { default = "nginx-service" }
variable "mysql_engine_version" { default = "5.7" }
variable "rds_instance_class" { default = "db.t3.micro" }
variable "db_name" { default = "mydb" }
variable "db_user" { default = "user" }
variable "db_password" { default = "Passw0rd$2023" }
variable "ecr_repository_name" { default = "nginx-commit" }
variable "certificate_arn" { default = "arn:aws:acm:eu-west-1:533267130709:certificate/01b982b4-c528-4ce0-af65-88cb2b08ea09" }
EOF

# Initialize and Plan Terraform
cd $project_dir
terraform init
terraform plan
terraform apply
