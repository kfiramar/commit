#!/bin/bash

ecs_cluster_name="main-cluster" # Replace with your ECS cluster name
service_name="nginx-service" # Replace with your ECS service name
log_group_name="/ecs/nginx" # Replace with your actual log group name

# Fetch task ARNs for the ECS service
task_arns=$(aws ecs list-tasks --cluster $ecs_cluster_name --service-name $service_name --query "taskArns[]" --output text)
echo "Task ARNs: $task_arns"

# Fetch logs from CloudWatch Logs for each task
for task_arn in $task_arns; do
    task_id=$(echo $task_arn | awk -F'/' '{print $NF}')
    log_stream_name="ecs/nginx/$task_id"
    echo "Fetching logs for task: $task_id"
    aws logs get-log-events --log-group-name $log_group_name --log-stream-name $log_stream_name --limit 50
done