# ──────────────────────────────────────────────────────────
# SnackyNerds — Terraform Outputs
# ──────────────────────────────────────────────────────────

# ── S3 ──
output "s3_bucket_id" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.snackynerds.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.snackynerds.arn
}

# ── ECR ──
output "ecr_repository_url" {
  description = "ECR repository URL (used for docker push)"
  value       = aws_ecr_repository.snackynerds.repository_url
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = aws_ecr_repository.snackynerds.registry_id
}

# ── ECS ──
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.snackynerds.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.snackynerds.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.snackynerds.arn
}

# ── Networking ──
output "security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs_tasks.id
}

# ── EKS ──
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.snackynerds.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.snackynerds.endpoint
}
