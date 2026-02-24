variable "app_name"{}
variable "region" {}
variable "subnets" { type = list(string) }
variable "ecs_sg" {}
variable "target_group_arn" {}
variable "container_port" {}
variable "ecr_image_url" {}


############################################
# Get default ECS execution role
############################################
data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

############################################
# CloudWatch Logs
############################################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${var.app_name}"
}

############################################
# ECS Cluster
############################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-cluster"
}

############################################
# Task Definition
############################################
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = var.ecr_image_url
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${var.app_name}",
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

############################################
# ECS Service (Fargate Spot)
###########################################
resource "aws_ecs_service" "service" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    security_groups = [var.ecs_sg]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [aws_cloudwatch_log_group.ecs_logs]
}
