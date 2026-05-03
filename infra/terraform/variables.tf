# ──────────────────────────────────────────────────────────
# SnackyNerds — Input Variables
# ──────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Unique S3 bucket name"
  type        = string
  default     = "snackynerds-tfstate-230143"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "snackynerds"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "snackynerds-cluster"
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
  default     = "snackynerds-service"
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
