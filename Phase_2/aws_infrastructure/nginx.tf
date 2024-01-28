resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = jsonencode([{
    name          = "nginx",
    image         = "533267130709.dkr.ecr.eu-west-2.amazonaws.com/nginx-commit:latest",
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/nginx"
        awslogs-region        = "eu-west-2"
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
