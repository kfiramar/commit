variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet1_cidr" { default = "10.0.1.0/24" }
variable "subnet2_cidr" { default = "10.0.2.0/24" }
variable "availability_zone1" { default = "eu-west-2a" }
variable "availability_zone2" { default = "eu-west-2b" }
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
variable "db_password" { default = "Passw0rd023" }
variable "ecr_repository_name" { default = "nginx-commit" }
variable "certificate_arn" { default = "arn:aws:acm:eu-west-2:753392824297:certificate/e637a974-5183-4379-851c-fc2758b38ce6" }
