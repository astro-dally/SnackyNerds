# 🚀 SnackyNerds — CI/CD Pipeline & AWS Infrastructure

> **Phase 2**: Automated Testing → Terraform Provisioning → Docker Build → ECS Fargate Deployment

This directory contains the Infrastructure-as-Code (IaC) and CI/CD configuration for deploying the SnackyNerds API to **AWS ECS Fargate** using a fully automated GitHub Actions pipeline.

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [What We Built](#-what-we-built)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Quick Start Guide](#-quick-start-guide)
- [Pipeline Phases](#-pipeline-phases)
- [Terraform Resources](#-terraform-resources)
- [Dockerfile Breakdown](#-dockerfile-breakdown)
- [GitHub Secrets Setup](#-github-secrets-setup)
- [Useful Commands](#-useful-commands)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)

---

## 🏗 Architecture Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   GitHub     │────▶│   Terraform  │────▶│   Docker +   │────▶│  ECS Fargate │
│   Actions    │     │   (AWS Infra)│     │   ECR Push   │     │  Deployment  │
│              │     │              │     │              │     │              │
│  • Run Tests │     │  • S3 Bucket │     │  • Build Img │     │  • Update TD │
│  • Lint Code │     │  • ECR Repo  │     │  • Tag + Push│     │  • Deploy    │
│  • Reports   │     │  • ECS Setup │     │              │     │  • Verify    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

**Flow**: `Push to main` → `Tests Pass` → `Terraform Apply` → `Docker Build & Push to ECR` → `Deploy to ECS Fargate`

---

## 🎯 What We Built

| Component | What It Does | Why We Need It |
|-----------|-------------|----------------|
| **GitHub Actions Pipeline** | Automates the entire CI/CD flow | No manual deployments — push and forget |
| **S3 Bucket** | Secure storage with versioning & encryption | Rubric requirement for Terraform-managed storage |
| **ECR Repository** | Private Docker image registry | Stores our container images securely on AWS |
| **ECS Fargate Cluster** | Serverless container orchestration | Runs our API without managing servers |
| **Security Group** | Network firewall rules | Controls who can access our API (port 5001) |
| **CloudWatch Logs** | Container log aggregation | Debug and monitor the running service |
| **Multi-Stage Dockerfile** | Optimized production container | Smaller image, non-root user, healthcheck |
| **JUnit Test Reports** | XML test result artifacts | Proof of test execution for grading |

---

## 🛠 Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.0 | Infrastructure as Code — provisions all AWS resources |
| **AWS Provider** | ~> 5.0 | Terraform plugin for AWS API interactions |
| **GitHub Actions** | v4 | CI/CD pipeline runner |
| **Docker** | Multi-stage | Containerization with production best practices |
| **AWS ECS Fargate** | — | Serverless container runtime (no EC2 instances to manage) |
| **AWS ECR** | — | Private container registry (like Docker Hub, but on AWS) |
| **AWS S3** | — | Object storage with versioning and encryption |
| **Jest + jest-junit** | 29.7 / 16.0 | Server-side testing with JUnit XML report generation |
| **Vitest** | 4.0 | Client-side testing with JUnit reporter |

---

## ✅ Prerequisites

Before running anything, make sure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws --version          # Should show aws-cli/2.x.x
   aws configure          # Set your credentials
   ```

2. **Terraform** installed
   ```bash
   terraform --version    # Should show Terraform v1.x.x
   ```

3. **Docker** installed (for local builds)
   ```bash
   docker --version       # Should show Docker version 2x.x.x
   ```

4. **Node.js 20+** (for running tests locally)
   ```bash
   node --version         # Should show v20.x.x
   ```

5. **AWS Academy Lab** started with active credentials

---

## ⚡ Quick Start Guide

### Step 1: Configure AWS Credentials

```bash
# Option A: AWS CLI configure
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1)

# Option B: Export environment variables (for session tokens)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_REGION="us-east-1"
```

### Step 2: Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and Variables** → **Actions** → **New repository secret**

Add these 4 secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_SESSION_TOKEN` | Your AWS session token (from Academy lab) |
| `AWS_REGION` | `us-east-1` |

### Step 3: Run Tests Locally (Verify Everything Works)

```bash
# Server tests
cd server
npm install
npm test
# ✅ Should see: 9 passed, junit.xml generated in reports/

# Client tests
cd ../client
npm install
npx vitest run
# ✅ Should see: tests passed
```

### Step 4: Provision Infrastructure with Terraform

```bash
cd infra/terraform

# Initialize Terraform (downloads AWS provider)
terraform init

# Validate the configuration
terraform validate
# ✅ Should see: "Success! The configuration is valid."

# See what will be created
terraform plan

# Apply — creates all AWS resources
terraform apply
# Type 'yes' when prompted
# ✅ Should see: "Apply complete! Resources: X added"
```

### Step 5: Build & Push Docker Image (Manual — Optional)

```bash
# Get ECR login credentials
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(terraform -chdir=infra/terraform output -raw ecr_repository_url | cut -d/ -f1)

# Build the image
docker build -t snackynerds:latest ./server

# Tag for ECR
ECR_URL=$(terraform -chdir=infra/terraform output -raw ecr_repository_url)
docker tag snackynerds:latest $ECR_URL:latest

# Push to ECR
docker push $ECR_URL:latest
```

### Step 6: Push to GitHub & Let the Pipeline Do Its Thing

```bash
git add .
git commit -m "feat: add CI/CD pipeline with Terraform, ECR, and ECS Fargate"
git push origin main
```

Then go to **Actions** tab in GitHub and watch the 4-phase pipeline run! 🎬

---

## 🔄 Pipeline Phases

The pipeline is defined in [`.github/workflows/pipeline.yml`](../.github/workflows/pipeline.yml) and has 4 sequential jobs:

### Phase 1 — Testing (`test`)

**Triggers on**: Every push and PR to `main`

| Step | What It Does |
|------|-------------|
| Install server deps | `npm ci` in `server/` |
| Run server tests | Jest with JUnit XML reporter → `server/reports/junit.xml` |
| Upload server report | Artifact: `server-test-report` |
| Install client deps | `npm ci` in `client/` |
| Run client tests | Vitest with JUnit reporter → `client/reports/junit.xml` |
| Upload client report | Artifact: `client-test-report` |
| Lint client | ESLint check |
| Build client | Vite production build |

### Phase 2 — Terraform (`terraform`)

**Triggers on**: Push to `main` only (not PRs)  
**Depends on**: Phase 1 passing

| Step | What It Does |
|------|-------------|
| Configure AWS | Sets up credentials from GitHub Secrets |
| `terraform init` | Downloads providers, initializes backend |
| `terraform validate` | Checks HCL syntax and configuration |
| `terraform plan` | Shows what resources will be created/changed |
| `terraform apply` | Creates/updates all AWS infrastructure |
| Capture outputs | Saves ECR URL, ECS cluster/service names for next jobs |

### Phase 3 — Docker Build & Push (`docker-build`)

**Depends on**: Phase 2 passing

| Step | What It Does |
|------|-------------|
| Login to ECR | Authenticates Docker with AWS ECR |
| Build image | Multi-stage build from `server/Dockerfile` |
| Tag image | Tags with both `git-sha` and `latest` |
| Push to ECR | Pushes both tags to the private registry |

### Phase 4 — Deploy to ECS (`deploy-ecs`)

**Depends on**: Phase 3 passing

| Step | What It Does |
|------|-------------|
| Register task def | Creates new ECS task definition revision with updated image |
| Update service | Tells ECS to deploy the new task definition |
| Wait for stability | Waits until new containers are running and healthy |
| Verify deployment | Confirms running count matches desired count |
| Print endpoint | Shows the public IP where the API is accessible |

---

## 🏗 Terraform Resources

All Terraform files are in [`infra/terraform/`](./terraform/):

| File | Resources Created | Rubric Requirement |
|------|-------------------|-------------------|
| **`s3.tf`** | S3 Bucket + Versioning + Encryption + Public Access Block | ✅ Unique name, versioning, encryption, no public |
| **`ecr.tf`** | ECR Repository + Lifecycle Policy | ✅ Private image registry |
| **`ecs.tf`** | ECS Cluster + Task Definition + Service | ✅ Fargate deployment |
| **`iam.tf`** | Data source for AWS Academy LabRole | ✅ Task execution role |
| **`networking.tf`** | Default VPC (data) + Security Group | ✅ Network access control |
| **`main.tf`** | AWS Provider configuration | — |
| **`variables.tf`** | All input variables | — |
| **`outputs.tf`** | ECR URL, ECS names, S3 ARN | — |
| **`terraform.tfvars`** | Default values | — |

### S3 Bucket Configuration

```
Bucket Name:    snackynerds-tfstate-230143
Versioning:     ✅ Enabled
Encryption:     ✅ AES256 (Server-Side)
Public Access:  ✅ Fully Blocked (all 4 flags)
```

---

## 🐳 Dockerfile Breakdown

The [`server/Dockerfile`](../server/Dockerfile) uses a **multi-stage build**:

```
┌─────────────────────────────┐
│  Stage 1: BUILDER           │
│  • node:20-bookworm-slim    │
│  • npm ci --omit=dev        │
│  • prisma generate          │
│  • (dev deps excluded)      │
└──────────────┬──────────────┘
               │ COPY --from=builder
┌──────────────▼──────────────┐
│  Stage 2: PRODUCTION        │
│  • node:20-bookworm-slim    │
│  • openssl + curl only      │
│  • Non-root user: snacky    │
│  • HEALTHCHECK configured   │
│  • CMD: node src/index.js   │
└─────────────────────────────┘
```

| Rubric Requirement | Implementation |
|-------------------|----------------|
| **Multi-stage build** | `builder` stage (install + build) → `production` stage (lean runtime) |
| **Non-root user** | `groupadd snacky` + `useradd snacky` → `USER snacky` |
| **Healthcheck** | `curl -f http://localhost:5001/api/health` every 30s |

---

## 🔑 GitHub Secrets Setup

Navigate to: **Repo** → **Settings** → **Secrets and Variables** → **Actions**

| Secret | Where to Find It | Example |
|--------|------------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Academy Lab → AWS Details | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Academy Lab → AWS Details | `wJal...` |
| `AWS_SESSION_TOKEN` | AWS Academy Lab → AWS Details | `FwoG...` (long string) |
| `AWS_REGION` | Fixed value | `us-east-1` |

> ⚠️ **Note**: AWS Academy session tokens expire when your lab session ends. You'll need to update `AWS_SESSION_TOKEN` each time you start a new lab session.

---

## 🔧 Useful Commands

### Terraform

```bash
cd infra/terraform

# See current state of resources
terraform show

# See all outputs
terraform output

# Get a specific output
terraform output ecr_repository_url

# Destroy everything (cleanup)
terraform destroy

# Format all .tf files
terraform fmt
```

### AWS CLI — Check Resources

```bash
# Check S3 bucket
aws s3 ls | grep snackynerds

# Check ECR images
aws ecr list-images --repository-name snackynerds

# Check ECS cluster
aws ecs list-clusters

# Check ECS services
aws ecs list-services --cluster snackynerds-cluster

# Check running tasks
aws ecs list-tasks --cluster snackynerds-cluster --service-name snackynerds-service

# Get task public IP
TASK_ARN=$(aws ecs list-tasks --cluster snackynerds-cluster --service-name snackynerds-service --query 'taskArns[0]' --output text)
ENI_ID=$(aws ecs describe-tasks --cluster snackynerds-cluster --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Association.PublicIp' --output text

# Hit the health endpoint
curl http://<PUBLIC_IP>:5001/api/health
```

### Docker (Local)

```bash
# Build image locally
docker build -t snackynerds:latest ./server

# Run locally
docker run -p 5001:5001 snackynerds:latest

# Check healthcheck
curl http://localhost:5001/api/health
```

### Tests

```bash
# Server tests (with JUnit report)
cd server && npm test

# Client unit tests
cd client && npx vitest run

# Client E2E tests
cd client && npx playwright test
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Pipeline fails at Terraform** | Check if `AWS_SESSION_TOKEN` is expired. Start a new lab session and update the secret. |
| **ECR push fails** | Make sure Terraform ran successfully first (ECR repo must exist). Check ECR login step. |
| **ECS service not stable** | Check CloudWatch logs: `aws logs tail /ecs/snackynerds`. Could be a port mismatch or missing env vars. |
| **Terraform `LabRole` not found** | Make sure you're in the correct AWS Academy account. The LabRole is pre-provisioned. |
| **"Resource already exists"** | Terraform state might be out of sync. Try `terraform import` or `terraform destroy` and re-apply. |
| **Docker build fails in CI** | Check the Dockerfile syntax. The `server/.dockerignore` might be excluding needed files. |
| **Tests pass locally but fail in CI** | Check Node.js version (must be 20). Check if `npm ci` is used (not `npm install`). |

---

## 📁 Project Structure

```
SnackyNerds/
├── .github/
│   └── workflows/
│       └── pipeline.yml            # 🔄 Unified CI/CD pipeline (4 phases)
│
├── infra/                          # 🏗 Infrastructure-as-Code
│   ├── README.md                   # 📖 You are here!
│   └── terraform/
│       ├── main.tf                 # AWS provider config
│       ├── variables.tf            # Input variables
│       ├── terraform.tfvars        # Variable values
│       ├── s3.tf                   # S3 bucket (versioned, encrypted, private)
│       ├── ecr.tf                  # ECR container registry
│       ├── ecs.tf                  # ECS cluster + task + service
│       ├── iam.tf                  # IAM (AWS Academy LabRole)
│       ├── networking.tf           # VPC + security group
│       └── outputs.tf              # Terraform outputs
│
├── server/                         # 🖥 Express.js API
│   ├── Dockerfile                  # Multi-stage, non-root, healthcheck
│   ├── src/                        # Application code
│   ├── tests/                      # Jest tests
│   └── reports/                    # JUnit XML test reports (generated)
│
├── client/                         # 🌐 React (Vite) frontend
│   ├── src/                        # Application code
│   └── tests/                      # Vitest + Playwright tests
│
└── README.md                       # Main project README
```

---

*Built for DevOps Phase 2 — by @astro-dally* 🍿
