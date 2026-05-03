# ──────────────────────────────────────────────────────────
# SnackyNerds — EKS Cluster + Node Group
# Kubernetes deployment alongside existing ECS
# ──────────────────────────────────────────────────────────

# ── EKS Cluster ──
resource "aws_eks_cluster" "snackynerds" {
  name     = var.eks_cluster_name
  role_arn = data.aws_iam_role.lab_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids         = data.aws_subnets.eks_compatible.ids
    security_group_ids = [aws_security_group.eks_cluster.id]

    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = {
    Name      = "SnackyNerds EKS Cluster"
    Project   = "SnackyNerds"
    ManagedBy = "terraform"
  }
}

# ── EKS Managed Node Group ──
resource "aws_eks_node_group" "snackynerds" {
  cluster_name    = aws_eks_cluster.snackynerds.name
  node_group_name = "snackynerds-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = data.aws_subnets.eks_compatible.ids

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  tags = {
    Name      = "SnackyNerds EKS Nodes"
    Project   = "SnackyNerds"
    ManagedBy = "terraform"
  }

  # Node group depends on the cluster being fully ready
  depends_on = [aws_eks_cluster.snackynerds]
}
