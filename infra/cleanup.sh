#!/bin/bash
# ──────────────────────────────────────────────────────────
# SnackyNerds — AWS Resource Cleanup Script
# Run this before pushing to main so the pipeline can
# create everything fresh for a clean demo.
#
# Usage: ./infra/cleanup.sh
# ──────────────────────────────────────────────────────────

# Do NOT use set -e — we want to continue even if some resources are already gone
REGION="${AWS_REGION:-us-east-1}"
ECR_REPO="snackynerds"
ECS_CLUSTER="snackynerds-cluster"
ECS_SERVICE="snackynerds-service"
TASK_FAMILY="snackynerds-task"
S3_BUCKET="snackynerds-tfstate-230143"
LOG_GROUP="/ecs/snackynerds"
SG_NAME="snackynerds-ecs-sg"
EKS_CLUSTER="snackynerds-eks"
EKS_NODE_GROUP="snackynerds-nodes"
EKS_SG_NAME="snackynerds-eks-sg"

echo ""
echo "════════════════════════════════════════════════"
echo "  🧹 SnackyNerds — AWS Cleanup"
echo "  Region: $REGION"
echo "════════════════════════════════════════════════"
echo ""

# ── 1. Stop & Delete ECS Service ──
echo "🔄 [1/7] Deleting ECS service..."
SERVICE_STATUS=$(aws ecs describe-services \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE" \
    --region "$REGION" \
    --query 'services[0].status' \
    --output text 2>/dev/null || echo "MISSING")

if [ "$SERVICE_STATUS" = "ACTIVE" ]; then
    aws ecs update-service \
        --cluster "$ECS_CLUSTER" \
        --service "$ECS_SERVICE" \
        --desired-count 0 \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    aws ecs delete-service \
        --cluster "$ECS_CLUSTER" \
        --service "$ECS_SERVICE" \
        --force \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    echo "   ✅ ECS service deleted"
else
    echo "   ⏭️  ECS service not found or already inactive"
fi

# ── 2. Deregister ALL Task Definition revisions ──
echo "🔄 [2/7] Deregistering task definitions..."
TASK_DEFS=$(aws ecs list-task-definitions \
    --family-prefix "$TASK_FAMILY" \
    --region "$REGION" \
    --query 'taskDefinitionArns[]' \
    --output text 2>/dev/null || echo "")

if [ -n "$TASK_DEFS" ] && [ "$TASK_DEFS" != "None" ]; then
    COUNT=0
    for td in $TASK_DEFS; do
        aws ecs deregister-task-definition \
            --task-definition "$td" \
            --region "$REGION" \
            --no-cli-pager > /dev/null 2>&1 || true
        COUNT=$((COUNT + 1))
    done
    echo "   ✅ Deregistered $COUNT task definition(s)"
else
    echo "   ⏭️  No task definitions found"
fi

# ── 3. Delete ECS Cluster ──
echo "🔄 [3/7] Deleting ECS cluster..."
CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters "$ECS_CLUSTER" \
    --region "$REGION" \
    --query 'clusters[0].status' \
    --output text 2>/dev/null || echo "MISSING")

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    aws ecs delete-cluster \
        --cluster "$ECS_CLUSTER" \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    echo "   ✅ ECS cluster deleted"
else
    echo "   ⏭️  ECS cluster not found or already deleted"
fi

# ── 4. Delete ECR Repository (with all images) ──
echo "🔄 [4/7] Deleting ECR repository..."
if aws ecr describe-repositories \
    --repository-names "$ECR_REPO" \
    --region "$REGION" > /dev/null 2>&1; then
    aws ecr delete-repository \
        --repository-name "$ECR_REPO" \
        --force \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    echo "   ✅ ECR repository deleted (with all images)"
else
    echo "   ⏭️  ECR repository not found"
fi

# ── 5. Delete S3 Bucket (including versioned objects) ──
echo "🔄 [5/7] Deleting S3 bucket..."
if aws s3api head-bucket --bucket "$S3_BUCKET" --region "$REGION" 2>/dev/null; then
    echo "   Removing all objects..."
    aws s3 rm "s3://$S3_BUCKET" --recursive --region "$REGION" > /dev/null 2>&1 || true

    echo "   Removing versioned objects..."
    # Delete all versions
    VERSIONS=$(aws s3api list-object-versions \
        --bucket "$S3_BUCKET" \
        --region "$REGION" \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
        --output json 2>/dev/null || echo '{"Objects": null}')

    if echo "$VERSIONS" | jq -e '.Objects != null and (.Objects | length > 0)' > /dev/null 2>&1; then
        aws s3api delete-objects \
            --bucket "$S3_BUCKET" \
            --delete "$VERSIONS" \
            --region "$REGION" \
            --no-cli-pager > /dev/null 2>&1 || true
    fi

    # Delete all delete markers
    MARKERS=$(aws s3api list-object-versions \
        --bucket "$S3_BUCKET" \
        --region "$REGION" \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
        --output json 2>/dev/null || echo '{"Objects": null}')

    if echo "$MARKERS" | jq -e '.Objects != null and (.Objects | length > 0)' > /dev/null 2>&1; then
        aws s3api delete-objects \
            --bucket "$S3_BUCKET" \
            --delete "$MARKERS" \
            --region "$REGION" \
            --no-cli-pager > /dev/null 2>&1 || true
    fi

    echo "   Deleting bucket..."
    aws s3api delete-bucket \
        --bucket "$S3_BUCKET" \
        --region "$REGION" > /dev/null 2>&1 || true
    echo "   ✅ S3 bucket deleted"
else
    echo "   ⏭️  S3 bucket not found"
fi

# ── 6. Delete CloudWatch Log Group ──
echo "🔄 [6/7] Deleting CloudWatch log group..."
if aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --region "$REGION" \
    --query 'logGroups[?logGroupName==`'"$LOG_GROUP"'`].logGroupName' \
    --output text 2>/dev/null | grep -q "$LOG_GROUP"; then
    aws logs delete-log-group \
        --log-group-name "$LOG_GROUP" \
        --region "$REGION" > /dev/null 2>&1 || true
    echo "   ✅ CloudWatch log group deleted"
else
    echo "   ⏭️  CloudWatch log group not found"
fi

# ── 7. Delete Security Group ──
echo "🔄 [7/7] Deleting security group..."
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SG_NAME" \
    --region "$REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || echo "None")

if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "   Waiting for ENIs to detach..."
    sleep 10
    aws ec2 delete-security-group \
        --group-id "$SG_ID" \
        --region "$REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Security group deleted"
    else
        echo "   ⚠️  Could not delete SG — retrying in 15s..."
        sleep 15
        aws ec2 delete-security-group \
            --group-id "$SG_ID" \
            --region "$REGION" > /dev/null 2>&1 && \
            echo "   ✅ Security group deleted (retry)" || \
            echo "   ❌ Failed to delete SG — ENIs may still be attached. Try again in a minute."
    fi
else
    echo "   ⏭️  Security group not found"
fi

# ── 8. Delete EKS Kubernetes Resources ──
echo "🔄 [8/11] Deleting Kubernetes resources..."
if aws eks describe-cluster --name "$EKS_CLUSTER" --region "$REGION" > /dev/null 2>&1; then
    aws eks update-kubeconfig --name "$EKS_CLUSTER" --region "$REGION" > /dev/null 2>&1 || true
    kubectl delete namespace snackynerds --ignore-not-found > /dev/null 2>&1 || true
    echo "   ✅ Kubernetes namespace deleted"
else
    echo "   ⏭️  EKS cluster not found (skipping K8s cleanup)"
fi

# ── 9. Delete EKS Node Group ──
echo "🔄 [9/11] Deleting EKS node group..."
NODE_STATUS=$(aws eks describe-nodegroup \
    --cluster-name "$EKS_CLUSTER" \
    --nodegroup-name "$EKS_NODE_GROUP" \
    --region "$REGION" \
    --query 'nodegroup.status' \
    --output text 2>/dev/null || echo "MISSING")

if [ "$NODE_STATUS" = "ACTIVE" ]; then
    aws eks delete-nodegroup \
        --cluster-name "$EKS_CLUSTER" \
        --nodegroup-name "$EKS_NODE_GROUP" \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    echo "   ⏳ Node group deletion initiated (takes ~5 min)..."
    aws eks wait nodegroup-deleted \
        --cluster-name "$EKS_CLUSTER" \
        --nodegroup-name "$EKS_NODE_GROUP" \
        --region "$REGION" 2>/dev/null || true
    echo "   ✅ EKS node group deleted"
else
    echo "   ⏭️  EKS node group not found"
fi

# ── 10. Delete EKS Cluster ──
echo "🔄 [10/11] Deleting EKS cluster..."
CLUSTER_STATUS=$(aws eks describe-cluster \
    --name "$EKS_CLUSTER" \
    --region "$REGION" \
    --query 'cluster.status' \
    --output text 2>/dev/null || echo "MISSING")

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    aws eks delete-cluster \
        --name "$EKS_CLUSTER" \
        --region "$REGION" \
        --no-cli-pager > /dev/null 2>&1 || true
    echo "   ⏳ Cluster deletion initiated (takes ~5 min)..."
    aws eks wait cluster-deleted \
        --name "$EKS_CLUSTER" \
        --region "$REGION" 2>/dev/null || true
    echo "   ✅ EKS cluster deleted"
else
    echo "   ⏭️  EKS cluster not found"
fi

# ── 11. Delete EKS Security Group ──
echo "🔄 [11/11] Deleting EKS security group..."
EKS_SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$EKS_SG_NAME" \
    --region "$REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || echo "None")

if [ -n "$EKS_SG_ID" ] && [ "$EKS_SG_ID" != "None" ]; then
    sleep 5
    aws ec2 delete-security-group \
        --group-id "$EKS_SG_ID" \
        --region "$REGION" > /dev/null 2>&1 && \
        echo "   ✅ EKS security group deleted" || \
        echo "   ⚠️  Could not delete EKS SG — retry later"
else
    echo "   ⏭️  EKS security group not found"
fi

# ── Clean local Terraform state ──
echo ""
echo "🔄 Cleaning local Terraform state..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
if [ -d "$TF_DIR" ]; then
    rm -f "$TF_DIR/terraform.tfstate" "$TF_DIR/terraform.tfstate.backup" "$TF_DIR/tfplan"
    rm -rf "$TF_DIR/.terraform"
    echo "   ✅ Local Terraform state cleaned"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ All AWS resources cleaned up!"
echo ""
echo "  Next steps:"
echo "  1. git add . && git commit -m 'chore: cleanup'"
echo "  2. Push to main (or merge PR)"
echo "  3. Pipeline creates everything fresh 🚀"
echo "════════════════════════════════════════════════"
echo ""
