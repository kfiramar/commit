#!/bin/bash

# Define variables
ECS_CLUSTER_NAME="main-cluster"
SERVICE_NAME="nginx-service"
REGION="eu-west-1"

# Function to check ECS service status
check_service_status() {
    echo "Checking ECS service status..."
    aws ecs describe-services --region $REGION --cluster $ECS_CLUSTER_NAME --services $SERVICE_NAME
}

# Function to check ECS task definition
check_task_definition() {
    echo "Fetching the latest task definition..."
    aws ecs describe-task-definition --region $REGION --task-definition $TASK_DEFINITION_NAME
}

# Function to check network configuration
check_network_configuration() {
    echo "Checking network configuration for the ECS task..."
    # Replace with your task ARN
    TASK_ARN="arn:aws:ecs:eu-west-1:533267130709:task/main-cluster/683cea38eadb4cb49158a3e0d6a7e494"
    aws ecs describe-tasks --region $REGION --cluster $ECS_CLUSTER_NAME --tasks $TASK_ARN
}

# Function to check database connectivity from ECS task
check_database_connectivity() {
    echo "Testing database connectivity from the ECS Task..."
    # Replace with your database host and credentials
    DB_HOST="terraform-20240127190209862400000004.czukooq60o15.eu-west-1.rds.amazonaws.com"
    DB_USER="user"
    DB_PASSWORD="Passw0rd$2023"
    
    # Use the appropriate database client command (e.g., mysql, psql) to test connectivity
    # Example for MySQL:
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "SELECT 1;"
}

# Main script
echo "Starting ECS service debugging..."

# Check ECS service status
check_service_status

# Check ECS task definition
# Replace with the correct task definition name
TASK_DEFINITION_NAME="nginx:13"
check_task_definition

# Check network configuration
check_network_configuration

# Check database connectivity
check_database_connectivity

echo "Debugging completed."
