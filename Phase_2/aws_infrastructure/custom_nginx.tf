resource "aws_ecs_task_definition" "custom_nginx" {
  family                   = "custom_nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = jsonencode([{
    name          = "custom_nginx",
    image         = "533267130709.dkr.ecr.eu-west-1.amazonaws.com/nginx-commit:latest", # Replace with your actual ECR repository URL
    portMappings  = [{
      containerPort = var.nginx_container_port,
      hostPort      = var.nginx_host_port
    }]
  }])
}

resource "aws_ecs_service" "custom_nginx_service" {
  name             = var.custom_nginx_service_name
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.custom_nginx.arn
  launch_type      = "FARGATE"
  desired_count    = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "custom_nginx"
    container_port   = var.nginx_container_port
  }

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  depends_on = [aws_lb_listener.https_listener]
}
