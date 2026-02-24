variable "subnets" {}
variable "ecs_sg" {}
variable "target_group_arn" {}
variable "container_port" {}
variable "ecr_image_url" {}
variable "app_name" {}
variable "region" {}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/${var.app_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_iam_role" "execution_role" {
  name = "${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "exec_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "512"
  memory = "1024"
  execution_role_arn = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = var.ecr_image_url

      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
      }]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = "1337" }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.ecs_sg]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight = 1
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = 3
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "strapi"
    container_port   = var.container_port
  }
}
