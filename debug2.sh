#!/bin/bash

ecs_cluster_name="main-cluster" # Replace with your ECS cluster name
service_name="nginx-service" # Replace with your ECS service name

# Fetch the current task definition used by the ECS service
task_definition_arn=$(aws ecs describe-services --cluster $ecs_cluster_name --services $service_name --query "services[0].taskDefinition" --output text)
echo "Current task definition ARN: $task_definition_arn"

# Retrieve and display the log configuration
aws ecs describe-task-definition --task-definition $task_definition_arn --query "taskDefinition.containerDefinitions[0].logConfiguration"
