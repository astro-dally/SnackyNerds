# ──────────────────────────────────────────────────────────
# SnackyNerds — Terraform Configuration
# Provider + Backend
# ──────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "snackynerds-tfstate-239257881562"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
