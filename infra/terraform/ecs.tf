# ──────────────────────────────────────────────────────────
# SnackyNerds — ECS Fargate
# Cluster + Task Definition + Service
# ──────────────────────────────────────────────────────────

# ── ECS Cluster ──
resource "aws_ecs_cluster" "snackynerds" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name        = "SnackyNerds ECS Cluster"
    Project     = "SnackyNerds"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ── CloudWatch Log Group ──
resource "aws_cloudwatch_log_group" "snackynerds" {
  name              = "/ecs/snackynerds"
  retention_in_days = 7

  tags = {
    Project   = "SnackyNerds"
    ManagedBy = "terraform"
  }
}

# ── ECS Task Definition ──
resource "aws_ecs_task_definition" "snackynerds" {
  family                   = "snackynerds-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "snackynerds-api"
      image     = "${aws_ecr_repository.snackynerds.repository_url}:${var.app_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.snackynerds.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "PORT"
          value = tostring(var.app_port)
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
  ])

  tags = {
    Project   = "SnackyNerds"
    ManagedBy = "terraform"
  }
}

# ── ECS Service ──
resource "aws_ecs_service" "snackynerds" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.snackynerds.id
  task_definition = aws_ecs_task_definition.snackynerds.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Allow Terraform to deploy even if the image isn't pushed yet
  # The service will start once the image is available
  force_new_deployment = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = {
    Project   = "SnackyNerds"
    ManagedBy = "terraform"
  }

  # Ignore changes to task_definition so CI/CD can update it independently
  lifecycle {
    ignore_changes = [task_definition]
  }
}
