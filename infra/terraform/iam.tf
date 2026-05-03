# ──────────────────────────────────────────────────────────
# SnackyNerds — IAM Roles for ECS + EKS
# Uses AWS Academy LabRole
# ──────────────────────────────────────────────────────────

# ── Look up the existing AWS Academy LabRole ──
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# The LabRole is used for:
# - ECS Task Execution Role (pulling images from ECR, writing CloudWatch logs)
# - ECS Task Role (runtime permissions for the container)
# - EKS Cluster Role (managing the Kubernetes control plane)
# - EKS Node Group Role (EC2 instances running pods)
#
# In AWS Academy, creating custom IAM roles is restricted,
# so we reuse the pre-provisioned LabRole for everything.
