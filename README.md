# 🍿 SnackyNerds

SnackyNerds is a premium, high-energy snack shop experience for true nerds. Fuel your brain with our crunchy collection, manage your loot in the cart, and pay using **Snacky Coins** 🪙.

## 🚀 Features

- **Dynamic Snack Grid**: Explore our curated collection of snacks with real-time stock and price information.
- **Snacky Wallet**: Every user starts with a stash of Snacky Coins to spend.
- **Brutal Cart & Loot Management**: Easily add or remove items from your pack.
- **Terminal Checkout**: A seamless checkout experience with balance verification.
- **Vibrant Design**: A bold, "brutal" aesthetic with smooth animations and responsive layouts.

## 🛠 Tech Stack

### Frontend
- **React (Vite)**: For a lightning-fast user interface.
- **React Router**: Multi-page navigation (Home, Cart, Checkout, Success).
- **Vanilla CSS**: Custom "brutal" design system with animations and glassmorphism.

### Backend
- **Express.js**: Robust RESTful API.
- **Prisma ORM**: Modern database access.
- **SQLite**: Local database storage for simplicity and portability.

### DevOps & Infrastructure
- **GitHub Actions**: Automated CI/CD pipeline (test → deploy).
- **Terraform**: Infrastructure as Code for AWS resource provisioning.
- **Docker**: Multi-stage containerization with security best practices.
- **AWS ECR**: Private container image registry.
- **AWS ECS Fargate**: Serverless container deployment (Phase 3).
- **AWS EKS**: Managed Kubernetes deployment with 2 replicas (Phase 4).
- **AWS S3**: Secure object storage (versioned, encrypted, private).

### Testing
- **Jest + Supertest**: Server unit & integration tests.
- **Vitest**: Client unit tests.
- **Playwright**: End-to-end browser tests.

## 📦 Project Structure

```text
SnackyNerds/
├── .github/
│   └── workflows/
│       └── pipeline.yml          # CI/CD pipeline (5 jobs)
├── client/                       # React frontend (Vite)
│   ├── src/                      # Components, pages, design system
│   ├── tests/e2e/                # Playwright E2E tests
│   └── Dockerfile                # Client container (dev)
├── server/                       # Express backend
│   ├── src/                      # API routes and logic
│   ├── prisma/                   # Database schema, migrations, seed
│   ├── tests/                    # Jest unit & integration tests
│   └── Dockerfile                # Production multi-stage build
├── infra/                        # Infrastructure as Code
│   ├── terraform/                # Terraform (S3, ECR, ECS, EKS, IAM, networking)
│   ├── k8s/                      # Kubernetes manifests (namespace, deployment, service)
│   ├── cleanup.sh                # AWS resource cleanup script
│   └── README.md                 # Infrastructure documentation
├── learn.md                      # DevOps concepts & learning guide
├── ARCHITECTURE.md               # System architecture documentation
└── README.md                     # You are here!
```

---

## ⚡ Step-by-Step: What You Need to Do

### Step 1: Local Setup (One-Time)

```bash
# Clone the repo
git clone https://github.com/astro-dally/SnackyNerds.git
cd SnackyNerds

# Install server deps
cd server && npm install && cd ..

# Install client deps
cd client && npm install && cd ..
```

### Step 2: Run Tests Locally (Verify Everything Works)

```bash
# Server tests (should show 9 passed)
cd server && npm test

# Client unit tests
cd client && npx vitest run
```

### Step 3: Configure AWS Credentials

```bash
# Option A: AWS CLI
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1)

# Option B: Environment variables (for session tokens)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_REGION="us-east-1"
```

### Step 4: Add GitHub Secrets

Go to: **Repo** → **Settings** → **Secrets and Variables** → **Actions** → **New repository secret**

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_SESSION_TOKEN` | Your session token (from AWS Academy) |
| `AWS_REGION` | `us-east-1` |

### Step 5: Clean Up Old Resources (If Any Exist)

```bash
./infra/cleanup.sh
```

> ⚠️ Run this before every fresh deployment. It deletes all AWS resources (ECS, EKS, ECR, S3, etc.) so the pipeline can create them clean.

### Step 6: Commit & Push

```bash
git add .
git commit -m "feat: deploy to ECS + EKS"
git push origin test
```

### Step 7: Create PR & Merge

1. Go to GitHub → **Pull Requests** → **New Pull Request**
2. Set base: `main` ← compare: `test`
3. Create PR → **only Phase 1 (tests) runs**
4. Merge PR → **ALL 5 phases run automatically**

### Step 8: Watch the Pipeline

Go to **Actions** tab and watch:

```
Phase 1 — Tests ✅
  ↓
Phase 2 — Terraform ✅ (creates S3, ECR, ECS, EKS ~15 min)
  ↓
Phase 3 — Docker Build & Push ✅
  ↓
Phase 3b — Deploy to ECS ✅ → prints http://<IP>:5001
  ↓ (parallel)
Phase 4 — Deploy to EKS ✅ → prints http://<LB-DNS>:5001
```

### Step 9: Verify Deployment

```bash
# Check ECS (from pipeline output)
curl http://<ECS_PUBLIC_IP>:5001/api/health
curl http://<ECS_PUBLIC_IP>:5001/api/snacks

# Check EKS (from pipeline output)
curl http://<EKS_LB_DNS>:5001/api/health
curl http://<EKS_LB_DNS>:5001/api/snacks

# Visit in browser to see the full frontend
open http://<IP>:5001
```

### Step 10: Clean Up After Demo

```bash
./infra/cleanup.sh
```

---

## 🔄 CI/CD Pipeline

```
Push to main
  ↓
Phase 1 — Tests (Jest + Vitest + JUnit Reports)
  ↓
Phase 2 — Terraform (S3 + ECR + ECS + EKS Infrastructure)
  ↓
Phase 3 — Docker Build & Push to ECR
  ↓
Phase 3b — Deploy to ECS Fargate     ← runs in parallel
Phase 4  — Deploy to EKS Kubernetes  ← runs in parallel
  ↓
🍿 App is live at:
   ECS → http://<PUBLIC_IP>:5001
   EKS → http://<LB_DNS>:5001
```

### GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_SESSION_TOKEN` | AWS session token (Academy) |
| `AWS_REGION` | AWS region (`us-east-1`) |

### Running Tests

```bash
# Server tests
cd server && npm test

# Client unit tests
cd client && npx vitest run

# Client E2E tests
cd client && npx playwright test
```

### Infrastructure Management

```bash
# Provision AWS resources
cd infra/terraform
terraform init
terraform plan
terraform apply

# Check EKS cluster
aws eks describe-cluster --name snackynerds-eks

# Check pods
aws eks update-kubeconfig --name snackynerds-eks
kubectl get pods -n snackynerds

# Clean up ALL AWS resources
./infra/cleanup.sh
```

> 📖 For detailed infrastructure docs, see [`infra/README.md`](infra/README.md)
>
> 📚 To learn the DevOps concepts behind this project, see [`learn.md`](learn.md)

## 🐳 Docker

The server uses a **production-grade multi-stage Dockerfile**:

- ✅ **Multi-stage build** — Builder stage for dependencies, lean production stage
- ✅ **Non-root user** — Runs as `snacky` user for security
- ✅ **Healthcheck** — Monitors `/api/health` every 30 seconds
- ✅ **Auto-migration** — Initializes database on container startup

```bash
# Build locally
docker build -t snackynerds ./server

# Run locally
docker run -p 5001:5001 -e DATABASE_URL=file:/app/prisma/dev.db snackynerds
```

## ☸️ Kubernetes (EKS)

Deployed with 3 manifest files in `infra/k8s/`:

- ✅ **Non-default namespace** — `snackynerds`
- ✅ **2 replicas** — High availability
- ✅ **Resource limits** — CPU and memory caps defined
- ✅ **Liveness probe** — Restarts unhealthy containers
- ✅ **Readiness probe** — Stops traffic to unready pods
- ✅ **LoadBalancer service** — External endpoint via AWS ELB

```bash
# Check deployment status
kubectl get all -n snackynerds

# Check pod logs
kubectl logs -n snackynerds -l app=snackynerds-api --tail=50

# Get LoadBalancer URL
kubectl get svc -n snackynerds
```

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check |
| `GET` | `/api/snacks` | List all snacks |
| `GET` | `/api/snacks/:id` | Get single snack |
| `POST` | `/api/snacks` | Create a snack |
| `PUT` | `/api/snacks/:id` | Update a snack |
| `DELETE` | `/api/snacks/:id` | Delete a snack |

---

*Built by @astro-dally* 🚀
