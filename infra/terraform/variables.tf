# ──────────────────────────────────────────────────────────
# SnackyNerds — Input Variables
# ──────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}


variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "snackynerds1"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "snackynerds-cluster1"
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
  default     = "snackynerds-service1"
}

variable "app_port" {
  description = "Container port for the application"
  type        = number
  default     = 5001
}

variable "app_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "snackynerds-eks1"
}



variable "desired_task_count" {
  description = "Desired number of running tasks/deployments"
  type        = number
  default     = 1
}

