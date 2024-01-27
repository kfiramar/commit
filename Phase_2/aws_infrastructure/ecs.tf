resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
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


resource "aws_ecs_task_definition" "nginx" {
  family                   = var.nginx_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([{
    name  = "nginx",
    image = var.nginx_image,
    portMappings = [{
      containerPort = var.nginx_container_port,
      hostPort      = var.nginx_host_port
    }]
  }])
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

resource "aws_lb_listener" "https" {
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
