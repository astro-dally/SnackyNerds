# ──────────────────────────────────────────────────────────
# SnackyNerds — Networking
# Uses default VPC (no custom VPC needed for class project)
# ──────────────────────────────────────────────────────────

# ── Default VPC ──
data "aws_vpc" "default" {
  default = true
}

# ── Default Subnets ──
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# ── Security Group for ECS Tasks ──
resource "aws_security_group" "ecs_tasks" {
  name        = "snackynerds-ecs-sg"
  description = "Allow inbound traffic to SnackyNerds API"
  vpc_id      = data.aws_vpc.default.id

  # Inbound: Allow traffic on app port
  ingress {
    description = "Allow API traffic"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all (needed for pulling images, DNS, etc.)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SnackyNerds ECS SG"
    Project     = "SnackyNerds"
    ManagedBy   = "terraform"
  }
}
