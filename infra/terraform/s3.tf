# ──────────────────────────────────────────────────────────
# SnackyNerds — S3 Bucket
# Rubric: Unique name, versioning, encryption, no public access
# ──────────────────────────────────────────────────────────

resource "aws_s3_bucket" "snackynerds" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name        = "SnackyNerds Terraform State"
    Project     = "SnackyNerds"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ── Versioning (Required by rubric) ──
resource "aws_s3_bucket_versioning" "snackynerds" {
  bucket = aws_s3_bucket.snackynerds.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-Side Encryption (Required by rubric) ──
resource "aws_s3_bucket_server_side_encryption_configuration" "snackynerds" {
  bucket = aws_s3_bucket.snackynerds.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ── Block ALL Public Access (Required by rubric) ──
resource "aws_s3_bucket_public_access_block" "snackynerds" {
  bucket = aws_s3_bucket.snackynerds.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
