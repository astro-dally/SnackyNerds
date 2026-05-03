#!/bin/bash
# ──────────────────────────────────────────────────────────
# SnackyNerds — AWS Resource Cleanup Script
# Run this before pushing to main so the pipeline can
# create everything fresh for a clean demo.
# ──────────────────────────────────────────────────────────

set -e

REGION="${AWS_REGION:-us-east-1}"
ECR_REPO="snackynerds"
ECS_CLUSTER="snackynerds-cluster"
ECS_SERVICE="snackynerds-service"
S3_BUCKET="snackynerds-tfstate-230143"
LOG_GROUP="/ecs/snackynerds"
SG_NAME="snackynerds-ecs-sg"

echo ""
echo "════════════════════════════════════════════════"
echo "  🧹 SnackyNerds — AWS Cleanup"
echo "  Region: $REGION"
echo "════════════════════════════════════════════════"
echo ""

# ── 1. Stop & Delete ECS Service ──
echo "🔄 [1/7] Checking ECS service..."
if aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --region "$REGION" --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
    echo "   Scaling service to 0..."
    aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --desired-count 0 --region "$REGION" --no-cli-pager > /dev/null 2>&1
    echo "   Deleting service..."
    aws ecs delete-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force --region "$REGION" --no-cli-pager > /dev/null 2>&1
    echo "   ✅ ECS service deleted"
else
    echo "   ⏭️  ECS service not found (already deleted)"
fi

# ── 2. Deregister Task Definitions ──
echo "🔄 [2/7] Cleaning up task definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix snackynerds-task --region "$REGION" --query 'taskDefinitionArns[]' --output text 2>/dev/null || echo "")
if [ -n "$TASK_DEFS" ] && [ "$TASK_DEFS" != "None" ]; then
    for td in $TASK_DEFS; do
        aws ecs deregister-task-definition --task-definition "$td" --region "$REGION" --no-cli-pager > /dev/null 2>&1
    done
    echo "   ✅ Task definitions deregistered"
else
    echo "   ⏭️  No task definitions found"
fi

# ── 3. Delete ECS Cluster ──
echo "🔄 [3/7] Checking ECS cluster..."
if aws ecs describe-clusters --clusters "$ECS_CLUSTER" --region "$REGION" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
    aws ecs delete-cluster --cluster "$ECS_CLUSTER" --region "$REGION" --no-cli-pager > /dev/null 2>&1
    echo "   ✅ ECS cluster deleted"
else
    echo "   ⏭️  ECS cluster not found (already deleted)"
fi

# ── 4. Delete ECR Repository ──
echo "🔄 [4/7] Checking ECR repository..."
if aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$REGION" > /dev/null 2>&1; then
    aws ecr delete-repository --repository-name "$ECR_REPO" --force --region "$REGION" --no-cli-pager > /dev/null 2>&1
    echo "   ✅ ECR repository deleted (with all images)"
else
    echo "   ⏭️  ECR repository not found (already deleted)"
fi

# ── 5. Delete S3 Bucket ──
echo "🔄 [5/7] Checking S3 bucket..."
if aws s3api head-bucket --bucket "$S3_BUCKET" --region "$REGION" 2>/dev/null; then
    echo "   Emptying bucket..."
    aws s3 rm "s3://$S3_BUCKET" --recursive --region "$REGION" > /dev/null 2>&1 || true
    # Also delete versioned objects
    aws s3api list-object-versions --bucket "$S3_BUCKET" --region "$REGION" --output json 2>/dev/null | \
        jq -r '.Versions[]? | "--key \(.Key) --version-id \(.VersionId)"' 2>/dev/null | \
        while read -r line; do
            aws s3api delete-object --bucket "$S3_BUCKET" $line --region "$REGION" > /dev/null 2>&1 || true
        done
    aws s3api list-object-versions --bucket "$S3_BUCKET" --region "$REGION" --output json 2>/dev/null | \
        jq -r '.DeleteMarkers[]? | "--key \(.Key) --version-id \(.VersionId)"' 2>/dev/null | \
        while read -r line; do
            aws s3api delete-object --bucket "$S3_BUCKET" $line --region "$REGION" > /dev/null 2>&1 || true
        done
    aws s3api delete-bucket --bucket "$S3_BUCKET" --region "$REGION" > /dev/null 2>&1
    echo "   ✅ S3 bucket deleted"
else
    echo "   ⏭️  S3 bucket not found (already deleted)"
fi

# ── 6. Delete CloudWatch Log Group ──
echo "🔄 [6/7] Checking CloudWatch log group..."
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$LOG_GROUP"; then
    aws logs delete-log-group --log-group-name "$LOG_GROUP" --region "$REGION" > /dev/null 2>&1
    echo "   ✅ CloudWatch log group deleted"
else
    echo "   ⏭️  CloudWatch log group not found (already deleted)"
fi

# ── 7. Delete Security Group ──
echo "🔄 [7/7] Checking security group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")
if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    # Wait a moment for ENIs to detach
    sleep 5
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" > /dev/null 2>&1 && \
        echo "   ✅ Security group deleted" || \
        echo "   ⚠️  Could not delete SG (may have active ENIs — wait a minute and retry)"
else
    echo "   ⏭️  Security group not found (already deleted)"
fi

# ── Clean local Terraform state ──
echo ""
echo "🔄 Cleaning local Terraform state..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
if [ -d "$TF_DIR" ]; then
    rm -f "$TF_DIR/terraform.tfstate" "$TF_DIR/terraform.tfstate.backup" "$TF_DIR/tfplan"
    rm -rf "$TF_DIR/.terraform"
    echo "   ✅ Local state cleaned"
else
    echo "   ⏭️  No terraform directory found"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Cleanup complete!"
echo "  Push to main to create everything fresh."
echo "════════════════════════════════════════════════"
echo ""
