# ──────────────────────────────────────────────────────────
# SnackyNerds — ECR Repository
# ──────────────────────────────────────────────────────────

resource "aws_ecr_repository" "snackynerds" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "SnackyNerds ECR"
    Project     = "SnackyNerds"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ── Lifecycle Policy: Keep last 10 images ──
resource "aws_ecr_lifecycle_policy" "snackynerds" {
  repository = aws_ecr_repository.snackynerds.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
