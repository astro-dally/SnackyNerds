# 🚀 SnackyNerds — CI/CD Pipeline & AWS Infrastructure

> Automated Testing → Terraform Provisioning → Docker Build → ECS Fargate + EKS Kubernetes Deployment

This directory contains the Infrastructure-as-Code (IaC), Kubernetes manifests, and CI/CD configuration for deploying the SnackyNerds API to **AWS ECS Fargate** and **AWS EKS** using a fully automated GitHub Actions pipeline.

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [What We Built](#-what-we-built)
- [Step-by-Step Guide](#-step-by-step-guide)
- [Pipeline Phases](#-pipeline-phases)
- [Terraform Resources](#-terraform-resources)
- [Kubernetes Manifests](#-kubernetes-manifests)
- [Dockerfile Breakdown](#-dockerfile-breakdown)
- [GitHub Secrets Setup](#-github-secrets-setup)
- [Useful Commands](#-useful-commands)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)

---

## 🏗 Architecture Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────────────┐
│   GitHub     │────▶│   Terraform  │────▶│   Docker +   │────▶│  ECS Fargate (1 task)│
│   Actions    │     │   (AWS Infra)│     │   ECR Push   │     │         AND           │
│              │     │              │     │              │     │  EKS K8s (2 pods)    │
│  • Run Tests │     │  • S3 Bucket │     │  • Build Img │     │  • Deploy            │
│  • JUnit XML │     │  • ECR Repo  │     │  • Tag + Push│     │  • Health Verify     │
│  • Lint/Build│     │  • ECS + EKS │     │              │     │  • Print URL         │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────────────┘
```

**Full flow**: `Push to main` → `Tests` → `Terraform Apply` → `Docker Build → ECR` → `Deploy to ECS + EKS (parallel)`

---

## 🎯 What We Built

| Component | What It Does | Phase |
|-----------|-------------|-------|
| **GitHub Actions Pipeline** | Automates the entire CI/CD flow | All |
| **S3 Bucket** | Secure storage (versioned, encrypted, private) | 2 |
| **ECR Repository** | Private Docker image registry | 2 |
| **ECS Fargate** | Serverless container (1 task) | 3 |
| **EKS Cluster** | Managed Kubernetes (2 nodes) | 4 |
| **K8s Deployment** | 2 replicas with probes + resource limits | 4 |
| **K8s LoadBalancer** | External endpoint for EKS | 4 |
| **Security Groups** | Firewall rules for ECS + EKS | 2 |
| **CloudWatch Logs** | Container log aggregation | 2 |
| **Multi-Stage Dockerfile** | Optimized production container | 3 |
| **JUnit Test Reports** | XML test result artifacts | 1 |

---

## ⚡ Step-by-Step Guide

### Prerequisites

Make sure you have these installed:

```bash
aws --version          # AWS CLI 2.x
terraform --version    # Terraform 1.x
docker --version       # Docker 2x.x
node --version         # Node.js 20.x
kubectl version --client  # kubectl (for EKS)
```

---

### Step 1: Configure AWS Credentials

```bash
# Get credentials from AWS Academy Lab → AWS Details
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_REGION="us-east-1"

# Verify
aws sts get-caller-identity
```

### Step 2: Add GitHub Secrets

Go to: **Repo** → **Settings** → **Secrets and Variables** → **Actions**

| Secret | Where to Find It |
|--------|------------------|
| `AWS_ACCESS_KEY_ID` | AWS Academy → AWS Details |
| `AWS_SECRET_ACCESS_KEY` | AWS Academy → AWS Details |
| `AWS_SESSION_TOKEN` | AWS Academy → AWS Details (long string) |
| `AWS_REGION` | `us-east-1` |

> ⚠️ Session tokens expire when your lab ends. Update `AWS_SESSION_TOKEN` each new session.

### Step 3: Run Tests Locally (Verify)

```bash
# Server tests (should show 9 passed)
cd server && npm install && npm test
# ✅ Output: Tests: 9 passed, junit.xml generated

# Client tests
cd ../client && npm install && npx vitest run
# ✅ Output: tests passed
```

### Step 4: Clean Up Old AWS Resources (If Any)

```bash
# From the project root
./infra/cleanup.sh
# ✅ Should show steps 1-11 with ✅ or ⏭️ for each
```

> Run this before every fresh demo. It removes: ECS service → cluster → ECR → S3 → CloudWatch → Security Groups → EKS namespace → node group → cluster → EKS SG

### Step 5: Provision Infrastructure (Option A: Manual)

```bash
cd infra/terraform

terraform init       # Download providers
terraform validate   # Check syntax
terraform plan       # Preview changes
terraform apply      # Create resources (type 'yes')
# ⚠️ First run takes ~15 min (EKS cluster creation)
```

### Step 5 (Alternative): Let the Pipeline Do It (Option B: Automatic)

```bash
# Just push to main — pipeline runs everything
git add . && git commit -m "feat: deploy" && git push origin test
# Then create PR test→main and merge
```

### Step 6: Push Code → Pipeline Runs

```bash
git add .
git commit -m "feat: full pipeline with ECS + EKS"
git push origin test

# Go to GitHub → Create PR (test → main) → Merge
# Pipeline runs all 5 jobs automatically
```

### Step 7: Watch Pipeline in Actions Tab

```
Phase 1 — Tests           ✅ (~1 min)
Phase 2 — Terraform       ✅ (~15 min first time, ~2 min after)
Phase 3 — Docker Build    ✅ (~3 min)
Phase 3b — Deploy ECS     ✅ (~2 min) → prints http://<IP>:5001
Phase 4 — Deploy EKS      ✅ (~3 min) → prints http://<LB>:5001
```

### Step 8: Verify Deployments

```bash
# From pipeline output, grab the URLs and test:

# ECS
curl http://<ECS_IP>:5001/api/health
# → {"status":"ok","message":"SnackyNerds Backend is running 🍿"}

# EKS
curl http://<EKS_LB_DNS>:5001/api/health
# → {"status":"ok","message":"SnackyNerds Backend is running 🍿"}

# Full frontend (both URLs)
open http://<IP>:5001
```

### Step 9: Check EKS with kubectl

```bash
# Configure kubectl
aws eks update-kubeconfig --name snackynerds-eks --region us-east-1

# Check all resources
kubectl get all -n snackynerds

# Should show:
# pod/snackynerds-api-xxxxx   1/1   Running
# pod/snackynerds-api-yyyyy   1/1   Running
# service/snackynerds-api     LoadBalancer   <LB_DNS>
# deployment.apps/snackynerds-api   2/2   2   2

# Check pod logs
kubectl logs -n snackynerds -l app=snackynerds-api --tail=20
```

### Step 10: Clean Up After Demo

```bash
./infra/cleanup.sh
# This deletes everything: ECS, ECR, S3, EKS cluster, nodes, SGs
```

---

## 🔄 Pipeline Phases

### Phase 1 — Testing (`test`)

| Step | What It Does |
|------|-------------|
| Install server deps | `npm ci` in `server/` |
| Run server tests | Jest + JUnit XML → `server/reports/junit.xml` |
| Upload server report | Artifact: `server-test-report` |
| Install client deps | `npm ci` in `client/` |
| Run client tests | Vitest + JUnit → `client/reports/junit.xml` |
| Upload client report | Artifact: `client-test-report` |
| Lint client | ESLint check |
| Build client | Vite production build |

### Phase 2 — Terraform (`terraform`)

| Step | What It Does |
|------|-------------|
| Configure AWS | Sets credentials from GitHub Secrets |
| `terraform init` | Downloads providers |
| `terraform validate` | Checks HCL syntax |
| `terraform plan` | Shows what will be created |
| `terraform apply` | Creates all AWS resources (S3, ECR, ECS, EKS) |

### Phase 3 — Docker Build & Push (`docker-build`)

| Step | What It Does |
|------|-------------|
| Get ECR URL | Queries AWS for the repository URL |
| Login to ECR | Authenticates Docker |
| Build React client | `npm ci && npm run build` in `client/` |
| Copy client to server | `client/dist/` → `server/public/` |
| Build Docker image | Multi-stage build from `server/Dockerfile` |
| Push to ECR | Tags with `git-sha` and `latest` |

### Phase 3b — Deploy to ECS (`deploy-ecs`)

| Step | What It Does |
|------|-------------|
| Register task def | Creates new revision with updated image |
| Update service | Tells ECS to deploy new task definition |
| Wait for stability | Waits for new container to be healthy |
| Verify | Checks running count = desired count |
| Print endpoint | Shows `http://<PUBLIC_IP>:5001` |

### Phase 4 — Deploy to EKS (`deploy-eks`) ← NEW

| Step | What It Does |
|------|-------------|
| Configure kubectl | `aws eks update-kubeconfig` |
| Get ECR URL | Queries AWS for image URL |
| Update manifest | `sed` replaces `IMAGE_PLACEHOLDER` with actual image |
| Apply manifests | `kubectl apply` namespace, deployment, service |
| Wait for rollout | `kubectl rollout status` (waits for 2/2 Ready) |
| Verify | Checks replica count + gets LoadBalancer DNS |

---

## 🏗 Terraform Resources

All files in [`terraform/`](./terraform/):

| File | Resources | Rubric |
|------|-----------|--------|
| **`s3.tf`** | S3 Bucket + Versioning + Encryption + Public Block | ✅ Phase 2 |
| **`ecr.tf`** | ECR Repository + Lifecycle Policy | ✅ Phase 2 |
| **`ecs.tf`** | ECS Cluster + Task Definition + Service | ✅ Phase 3 |
| **`eks.tf`** | EKS Cluster + Managed Node Group (2x t3.medium) | ✅ Phase 4 |
| **`iam.tf`** | AWS Academy LabRole (reused for ECS + EKS) | ✅ |
| **`networking.tf`** | Default VPC + ECS SG + EKS SG | ✅ |
| **`main.tf`** | AWS Provider config | — |
| **`variables.tf`** | All input variables | — |
| **`outputs.tf`** | ECR URL, ECS/EKS cluster names | — |
| **`terraform.tfvars`** | Default values | — |

---

## ☸️ Kubernetes Manifests

All files in [`k8s/`](./k8s/):

| File | What It Creates | Rubric Requirement |
|------|----------------|-------------------|
| **`namespace.yaml`** | `snackynerds` namespace | ✅ Non-default namespace |
| **`deployment.yaml`** | Deployment with 2 replicas | ✅ Min 2 replicas |
| | Resource requests + limits | ✅ Resource limits |
| | Liveness probe (`/api/health`) | ✅ Liveness probe |
| | Readiness probe (`/api/health`) | ✅ Readiness probe |
| **`service.yaml`** | LoadBalancer service | ✅ Expose endpoint |

### Deployment Config

```
Replicas:        2
CPU Request:     128m (12.8% of 1 core)
CPU Limit:       256m (25.6% of 1 core)
Memory Request:  256Mi
Memory Limit:    512Mi
Liveness:        GET /api/health every 10s (30s initial delay)
Readiness:       GET /api/health every 5s (10s initial delay)
Strategy:        Rolling update (0 downtime)
```

---

## 🐳 Dockerfile Breakdown

```
┌─────────────────────────────┐
│  Stage 1: BUILDER           │
│  • node:20-bookworm-slim    │
│  • npm ci (all deps)        │
│  • prisma generate          │
└──────────────┬──────────────┘
               │ COPY --from=builder
┌──────────────▼──────────────┐
│  Stage 2: PRODUCTION        │
│  • openssl + curl only      │
│  • Non-root user: snacky    │
│  • HEALTHCHECK configured   │
│  • CMD: migrate → seed →    │
│         start server        │
└─────────────────────────────┘
```

| Rubric | Implementation |
|--------|----------------|
| **Multi-stage build** | `builder` → `production` |
| **Non-root user** | `USER snacky` |
| **Healthcheck** | `curl /api/health` every 30s |

---

## 🔧 Useful Commands

### Terraform
```bash
cd infra/terraform
terraform show              # Current state
terraform output            # All outputs
terraform output ecr_repository_url  # Specific output
terraform destroy           # Tear down everything
terraform fmt               # Format .tf files
```

### AWS CLI — Check Resources
```bash
# S3
aws s3 ls | grep snackynerds

# ECR
aws ecr list-images --repository-name snackynerds

# ECS
aws ecs list-clusters
aws ecs list-services --cluster snackynerds-cluster
aws ecs list-tasks --cluster snackynerds-cluster --service-name snackynerds-service

# EKS
aws eks describe-cluster --name snackynerds-eks --query 'cluster.status'
aws eks list-nodegroups --cluster-name snackynerds-eks
```

### Kubernetes (EKS)
```bash
# Configure kubectl
aws eks update-kubeconfig --name snackynerds-eks --region us-east-1

# Check everything
kubectl get all -n snackynerds

# Check pods
kubectl get pods -n snackynerds -o wide

# Check pod logs
kubectl logs -n snackynerds -l app=snackynerds-api --tail=50

# Check service (LoadBalancer URL)
kubectl get svc -n snackynerds

# Describe deployment (detailed info)
kubectl describe deployment snackynerds-api -n snackynerds

# Watch pods in real-time
kubectl get pods -n snackynerds -w
```

### ECS — Get Public IP
```bash
TASK_ARN=$(aws ecs list-tasks --cluster snackynerds-cluster \
  --service-name snackynerds-service --query 'taskArns[0]' --output text)

ENI_ID=$(aws ecs describe-tasks --cluster snackynerds-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text
```

### Docker (Local)
```bash
docker build -t snackynerds:latest ./server
docker run -p 5001:5001 -e DATABASE_URL=file:/app/prisma/dev.db snackynerds:latest
curl http://localhost:5001/api/health
```

### Tests
```bash
cd server && npm test          # Server (Jest + JUnit)
cd client && npx vitest run    # Client unit tests
cd client && npx playwright test  # Client E2E tests
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Pipeline fails at Terraform** | Session token expired. Start new lab → update `AWS_SESSION_TOKEN` secret |
| **"AlreadyExists" errors** | Run `./infra/cleanup.sh` first, then push again |
| **ECR push fails** | Make sure Terraform succeeded first (ECR repo must exist) |
| **ECS task keeps restarting** | Check CloudWatch: `aws logs tail /ecs/snackynerds`. Likely missing `DATABASE_URL` |
| **EKS pods CrashLoopBackOff** | Check logs: `kubectl logs -n snackynerds -l app=snackynerds-api` |
| **EKS LoadBalancer pending** | Wait ~2 min. Check: `kubectl get svc -n snackynerds` |
| **"LabRole not found"** | Make sure you're in the correct AWS Academy account |
| **Docker build fails in CI** | Check `server/.dockerignore` isn't excluding needed files |
| **Can't connect to service** | Check security groups allow port 5001. Check the correct IP/DNS |
| **kubectl: connection refused** | Run `aws eks update-kubeconfig --name snackynerds-eks` |
| **EKS cluster takes forever** | Normal — first creation takes ~15 min. Subsequent runs are fast |

---

## 📁 Project Structure

```
infra/
├── terraform/
│   ├── main.tf                 # AWS provider config
│   ├── variables.tf            # Input variables
│   ├── terraform.tfvars        # Variable values
│   ├── s3.tf                   # S3 bucket (versioned, encrypted, private)
│   ├── ecr.tf                  # ECR container registry
│   ├── ecs.tf                  # ECS cluster + task + service
│   ├── eks.tf                  # EKS cluster + node group
│   ├── iam.tf                  # IAM (AWS Academy LabRole)
│   ├── networking.tf           # VPC + ECS SG + EKS SG
│   └── outputs.tf              # Terraform outputs
├── k8s/
│   ├── namespace.yaml          # snackynerds namespace
│   ├── deployment.yaml         # 2 replicas, probes, resource limits
│   └── service.yaml            # LoadBalancer service
├── cleanup.sh                  # AWS resource cleanup (ECS + EKS)
└── README.md                   # You are here!
```

---

*Built for DevOps Phases 2-4 — by @astro-dally* 🍿
