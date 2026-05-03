# 📚 SnackyNerds — What We Built & What We Learned

> A teaching document that walks through every DevOps concept we implemented, **why** it matters, and **what** we achieved.

---

## 🧭 The Big Picture

We took a working full-stack app (React + Express + SQLite) and built an **end-to-end automated deployment pipeline**. Before this, deploying meant SSHing into an EC2 instance and running commands manually. Now:

```
You push code → Everything happens automatically → App is live on AWS
```

That's the core idea of **CI/CD** (Continuous Integration / Continuous Deployment).

---

## 🔑 Core Concepts

### 1. CI/CD — Continuous Integration & Continuous Deployment

**What it is:** An automated pipeline that tests, builds, and deploys your code every time you push.

**Why it matters:** Without CI/CD, deploying looks like this:
```
Write code → Manually test → SSH into server → Pull code → Restart → Pray it works
```

With CI/CD:
```
Write code → Push → ✅ Everything happens automatically → App is live
```

**What we built:**
- A **GitHub Actions workflow** (`pipeline.yml`) with 4 sequential jobs
- Each job depends on the previous one passing — if tests fail, nothing deploys

**Key takeaway:** CI/CD eliminates human error from deployments. The pipeline is the same every time — no "it works on my machine" problems.

---

### 2. GitHub Actions — The Pipeline Runner

**What it is:** GitHub's built-in CI/CD platform. It reads YAML files in `.github/workflows/` and runs them on virtual machines (called "runners").

**Key concepts we used:**

| Concept | What it means | Our usage |
|---------|--------------|-----------|
| **Workflow** | A YAML file defining automation | `pipeline.yml` |
| **Job** | A group of steps that runs on one machine | `test`, `terraform`, `docker-build`, `deploy-ecs` |
| **Step** | A single command or action | `npm test`, `terraform apply`, etc. |
| **needs** | Job dependency — "run this only after X passes" | `terraform` needs `test` |
| **if** | Conditional execution | Deploy only on `push` to `main`, not on PRs |
| **Secrets** | Encrypted environment variables | AWS credentials |
| **Artifacts** | Files saved between jobs | Test reports (JUnit XML) |

**How our pipeline flows:**
```
Push to main
  ↓
[test] ──── Run Jest + Vitest, upload JUnit reports
  ↓ (needs: test)
[terraform] ── Init → Validate → Plan → Apply
  ↓ (needs: terraform)
[docker-build] ── Build image → Push to ECR
  ↓ (needs: docker-build)
[deploy-ecs] ── Update task → Deploy → Wait → Verify
```

**Key takeaway:** The `needs` keyword creates a dependency chain. If any job fails, downstream jobs are skipped. This prevents deploying broken code.

---

### 3. GitHub Secrets — Keeping Credentials Safe

**What it is:** Encrypted key-value pairs stored in your GitHub repo settings, injected into workflows at runtime.

**Why it matters:** You **never** put AWS credentials in your code. Anyone who reads your repo would have access to your AWS account.

**What we configured:**

| Secret | What it holds | Why we need it |
|--------|--------------|----------------|
| `AWS_ACCESS_KEY_ID` | AWS identity | Authenticate API calls |
| `AWS_SECRET_ACCESS_KEY` | AWS password | Prove you're authorized |
| `AWS_SESSION_TOKEN` | Temporary session | AWS Academy uses temporary credentials |
| `AWS_REGION` | `us-east-1` | Tell AWS which data center to use |

**How they're used in the pipeline:**
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}     # ← injected at runtime
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

The `${{ secrets.X }}` syntax is replaced with the actual value when the workflow runs — it never appears in logs.

**Key takeaway:** Secrets are the bridge between "code in GitHub" and "resources in AWS" without exposing credentials.

---

### 4. Terraform — Infrastructure as Code (IaC)

**What it is:** A tool that lets you define your cloud infrastructure in code (`.tf` files) instead of clicking through the AWS Console.

**Why it matters:**
- **Reproducible** — Run `terraform apply` and get the exact same infrastructure every time
- **Version controlled** — Infrastructure changes are tracked in Git like code
- **Reviewable** — You can see what will change before applying (`terraform plan`)
- **Destroyable** — One command tears everything down (`terraform destroy`)

**The Terraform workflow:**
```
terraform init      → Download provider plugins (like npm install for infra)
terraform validate  → Check syntax (like a linter)
terraform plan      → Preview what will be created/changed/destroyed
terraform apply     → Actually create the resources
terraform destroy   → Tear everything down
```

**What we created with Terraform:**

| Resource | File | What it does |
|----------|------|-------------|
| **S3 Bucket** | `s3.tf` | Secure object storage |
| **ECR Repository** | `ecr.tf` | Private Docker image registry |
| **ECS Cluster** | `ecs.tf` | Container orchestration cluster |
| **ECS Task Definition** | `ecs.tf` | Blueprint for running containers |
| **ECS Service** | `ecs.tf` | Keeps desired number of tasks running |
| **Security Group** | `networking.tf` | Firewall rules (allow port 5001) |
| **CloudWatch Log Group** | `ecs.tf` | Container log storage |

**Key files explained:**

- **`main.tf`** — "I want to use AWS, version 5.x, in us-east-1"
- **`variables.tf`** — Inputs (like function parameters): bucket name, region, ports
- **`terraform.tfvars`** — Actual values for those inputs
- **`outputs.tf`** — Things Terraform tells you after creating resources (like ECR URL)

**Key takeaway:** Terraform turns infrastructure into code. Instead of "I clicked 47 buttons in the AWS Console," you have a Git-tracked, reviewable, repeatable definition of your entire cloud setup.

---

### 5. S3 Bucket — Secure Cloud Storage

**What it is:** Amazon's object storage service. Think of it as a cloud hard drive.

**What we configured (rubric requirements):**

```hcl
# 1. Unique name — globally unique across ALL of AWS
bucket = "snackynerds-tfstate-230143"

# 2. Versioning — keep history of every file change
versioning_configuration {
  status = "Enabled"
}

# 3. Encryption — all data encrypted at rest
apply_server_side_encryption_by_default {
  sse_algorithm = "AES256"
}

# 4. No public access — block everything
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

**Why each matters:**
- **Versioning** → You can recover from accidental deletions or overwrites
- **Encryption** → Even if someone steals the physical disk, data is unreadable
- **No public access** → Prevents accidental data leaks (this is the #1 cause of cloud security breaches)

**Key takeaway:** S3 is simple but the security configuration is critical. The four public access block flags are the most important setting — leaving them off is how companies leak millions of records.

---

### 6. Docker — Containerization

**What it is:** Docker packages your app + all its dependencies into a single "container" that runs the same everywhere.

**The problem Docker solves:**
```
"It works on my machine!"
"But it crashes on the server..."
"We have different Node versions..."
```

With Docker, you define exactly what goes into the container. It's identical on your laptop, in CI, and on AWS.

**Our Dockerfile explained line by line:**

```dockerfile
# ── Stage 1: Builder ──
# Start from a Node.js 20 base image
FROM node:20-bookworm-slim AS builder
WORKDIR /app

# Install dependencies (including prisma for code generation)
COPY package*.json ./
RUN npm ci                    # Deterministic install from lockfile

COPY . .
RUN npx prisma generate       # Generate database client code

# ── Stage 2: Production ──
# Fresh image — only production stuff
FROM node:20-bookworm-slim AS production

# Runtime tools (openssl for Prisma, curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends openssl curl

# Security: don't run as root
RUN groupadd -r snacky && useradd -r -g snacky -m snacky

WORKDIR /app
COPY --from=builder --chown=snacky:snacky /app /app  # Copy from Stage 1

RUN npm ci --omit=dev && npx prisma generate  # Production deps only

USER snacky                   # Switch to non-root user
EXPOSE 5001

# Health monitoring
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:5001/api/health || exit 1

# Start: migrate DB → seed → run server
CMD ["sh", "-c", "npx prisma migrate deploy && node prisma/seed.js; node src/index.js"]
```

**Three rubric requirements and why they matter:**

| Requirement | What we did | Why it matters |
|-------------|------------|----------------|
| **Multi-stage build** | `builder` → `production` stages | Smaller image (no dev tools in production), faster deploys |
| **Non-root user** | `USER snacky` | If container is compromised, attacker has limited permissions |
| **Healthcheck** | `curl /api/health` every 30s | ECS knows when to restart unhealthy containers |

**Key takeaway:** Docker isn't just "packaging" — the Dockerfile IS your deployment documentation. Anyone can read it and understand exactly how your app runs in production.

---

### 7. ECR — Elastic Container Registry

**What it is:** AWS's private Docker Hub. You push Docker images here, and ECS pulls from here.

**The flow:**
```
Your code → Docker build → Push to ECR → ECS pulls from ECR → Container runs
```

**Why not Docker Hub?**
- ECR is private by default (Docker Hub images are public unless you pay)
- ECR is in the same AWS network as ECS — faster pulls
- ECR integrates with IAM — same permissions system as everything else

**What we configured:**
- **Image scanning** — automatically checks for known vulnerabilities
- **Lifecycle policy** — keeps only the last 10 images (saves storage costs)
- **Mutable tags** — allows overwriting the `latest` tag

**Key takeaway:** ECR is where your Docker images live in AWS. It's the bridge between "I built an image" and "ECS runs the image."

---

### 8. ECS Fargate — Serverless Containers

**What it is:** AWS ECS (Elastic Container Service) runs your Docker containers. Fargate is the "serverless" mode — you don't manage any servers.

**ECS vs EC2 deployment:**

| | EC2 (Phase 1) | ECS Fargate (Phase 2) |
|---|---|---|
| Server management | You manage the instance | AWS manages everything |
| Scaling | Manual | Automatic |
| Updates | SSH + git pull + restart | Push image → automatic |
| Cost | Pay for instance 24/7 | Pay per second of usage |
| Health monitoring | Manual scripts | Built-in healthchecks |

**ECS has three layers:**

```
ECS Cluster (snackynerds-cluster)
  └── ECS Service (snackynerds-service)
        └── ECS Task (running container)
              └── Container (snackynerds-api)
```

- **Cluster** → The "environment" where services run
- **Service** → Ensures X number of tasks are always running (we set 1)
- **Task Definition** → Blueprint: what image, how much CPU/memory, what ports, what env vars
- **Task** → An actual running instance of the task definition

**What happens during deployment:**
```
1. New Docker image pushed to ECR
2. New task definition revision registered (points to new image)
3. ECS service updated to use new task definition
4. ECS launches new task with new image
5. Health check passes → old task stopped
6. Service is stable with new version
```

**Key takeaway:** Fargate lets you focus on your app, not on servers. You describe WHAT you want to run (CPU, memory, port, image), and AWS handles WHERE and HOW.

---

### 9. Security Group — Cloud Firewall

**What it is:** A virtual firewall that controls what traffic can reach your containers.

**What we configured:**

```
INBOUND:  Allow TCP port 5001 from anywhere (0.0.0.0/0) → API access
OUTBOUND: Allow all traffic → Container can pull images, resolve DNS, etc.
```

**Why it matters:** Without a security group allowing port 5001, your container could be running perfectly but nobody could reach it. It's like running a web server behind a locked door.

**Key takeaway:** Security groups are the most common reason for "my service is running but I can't reach it." Always check the ports.

---

### 10. Test Reports — Proving Your Tests Ran

**What it is:** JUnit XML format — a standard way to report test results that CI tools understand.

**What we set up:**
- **Server tests** → Jest + `jest-junit` → produces `server/reports/junit.xml`
- **Client tests** → Vitest + `--reporter=junit` → produces `client/reports/junit.xml`
- Both uploaded as **GitHub Actions artifacts** (downloadable from the Actions tab)

**Why XML reports?**
- Machine-readable — CI tools can parse and display them
- Historical — you can download past reports
- Proof — "yes, I ran tests and here are the results"

**Key takeaway:** Tests aren't just about catching bugs — the reports are evidence that your CI pipeline actually validates the code before deploying.

---

### 11. EKS — Elastic Kubernetes Service

**What it is:** AWS's managed Kubernetes. You get a full Kubernetes cluster where AWS runs the control plane (API server, scheduler, etcd), and you run your containers on worker nodes.

**ECS vs EKS — When to use which:**

| | ECS (what we built first) | EKS (what we added) |
|---|---|---|
| **Complexity** | Simple — AWS-native API | Complex — full Kubernetes |
| **Industry adoption** | AWS-only shops | 80%+ of companies |
| **Config format** | Task Definitions (JSON) | YAML manifests (portable) |
| **Portability** | Locked to AWS | Works on any cloud (GKE, AKS, etc.) |
| **Learning curve** | Low | Higher, but more valuable |
| **Best for** | Small teams, simple apps | Large teams, microservices |

**What EKS creates on AWS:**
```
┌───────────────────────────────────────────────────┐
│  EKS Cluster (snackynerds-eks)                    │
│                                                   │
│  ┌──────────────────┐  ← Managed by AWS (you      │
│  │  Control Plane   │     never see these servers)  │
│  │  • API Server    │                               │
│  │  • Scheduler     │                               │
│  │  • etcd          │                               │
│  └──────────────────┘                               │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ← Node Group          │
│  │  Node 1  │  │  Node 2  │    (t3.medium EC2s)     │
│  │  (EC2)   │  │  (EC2)   │                         │
│  │  Pod A   │  │  Pod B   │  ← Your containers      │
│  └──────────┘  └──────────┘                         │
└───────────────────────────────────────────────────┘
```

**Key takeaway:** EKS is more complex than ECS but it's the industry standard. Learning Kubernetes is one of the highest-value skills in DevOps — it works the same on AWS, Google Cloud, Azure, or your laptop.

---

### 12. Kubernetes Concepts — The Building Blocks

Kubernetes has its own vocabulary. Here's what each piece does:

#### Namespace — Isolation
```yaml
kind: Namespace
metadata:
  name: snackynerds    # Our own isolated space
```
**What it does:** Like folders on your computer. Instead of dumping everything in `default`, our app lives in `snackynerds`. Other teams' apps live in their own namespaces. They don't interfere with each other.

**Rubric:** "Non-default namespace" ✅

---

#### Pod — The Smallest Unit
A **Pod** is one or more containers running together. In our case, each pod runs one `snackynerds-api` container.

You almost never create pods directly — you create a **Deployment** that manages pods for you.

---

#### Deployment — Desired State Manager

```yaml
kind: Deployment
spec:
  replicas: 2              # "I want 2 pods running at all times"
```

**What it does:** You tell Kubernetes "I want 2 copies of my app running." Kubernetes makes it happen and keeps it that way. If a pod crashes, Kubernetes automatically creates a new one.

**Rubric:** "Minimum 2 replicas" ✅

**ECS comparison:**
- ECS: `desired_count = 1` in the service
- K8s: `replicas: 2` in the deployment

---

#### Resource Limits — Fair Sharing

```yaml
resources:
  requests:              # Minimum guaranteed
    cpu: "128m"          # 128 millicores = 12.8% of one CPU core
    memory: "256Mi"      # 256 MiB of RAM
  limits:                # Maximum allowed
    cpu: "256m"          # Can burst up to 25.6% of one CPU
    memory: "512Mi"      # Hard cap — killed if exceeded
```

**Why it matters:**
- **requests** = "give me at least this much" → Kubernetes uses this to schedule pods on nodes
- **limits** = "never give me more than this" → Prevents one pod from starving others

Without limits, one buggy pod could eat all the memory and crash the entire node.

**Rubric:** "Resource limits defined" ✅

---

#### Liveness Probe — "Are You Alive?"

```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 5001
  initialDelaySeconds: 30    # Wait 30s before first check
  periodSeconds: 10          # Check every 10s
  failureThreshold: 3        # 3 failures = restart the container
```

**What it does:** Every 10 seconds, Kubernetes sends `GET /api/health` to the container. If it fails 3 times in a row, Kubernetes **kills and restarts** the container.

**Rubric:** "Liveness probe" ✅

---

#### Readiness Probe — "Are You Ready for Traffic?"

```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 5001
  initialDelaySeconds: 10    # Wait 10s before first check
  periodSeconds: 5           # Check every 5s
```

**What it does:** Even if a pod is "alive," it might not be ready (maybe it's still loading data or running migrations). The readiness probe controls when the Service starts sending traffic to this pod.

**The difference:**
- **Liveness** fails → Kubernetes **restarts** the container
- **Readiness** fails → Kubernetes **stops sending traffic** (but doesn't restart)

**Rubric:** "Readiness probe" ✅

---

#### Service (LoadBalancer) — Exposing Your App

```yaml
kind: Service
spec:
  type: LoadBalancer
  selector:
    app: snackynerds-api     # Route traffic to pods with this label
  ports:
    - port: 5001
```

**What it does:** Creates an AWS Load Balancer that:
1. Gets a public DNS name
2. Distributes traffic across all healthy pods
3. If a pod fails its readiness probe, traffic stops going to it

**Service types:**
| Type | What it does | When to use |
|---|---|---|
| `ClusterIP` | Internal only (no external access) | Microservice-to-microservice |
| `NodePort` | Opens a port on every node | Testing, simple access |
| `LoadBalancer` | Creates a cloud load balancer | **Production — what we use** |

**Rubric:** "Expose service endpoint" ✅

---

#### How It All Connects

```
Internet
  ↓
LoadBalancer (AWS ELB)
  ↓
Service (routes to healthy pods)
  ↓  ↓
Pod A   Pod B     ← Deployment ensures 2 running
  ↓      ↓
Container Container  ← Same Docker image from ECR
  ↓      ↓
/api/health ✅       ← Probes verify health
```

---

### 13. EKS Deployment Flow

**What happens when the pipeline deploys to EKS:**

```
1. aws eks update-kubeconfig → Configure kubectl to talk to our cluster
2. sed IMAGE_PLACEHOLDER → Replace placeholder with actual ECR image:tag
3. kubectl apply namespace.yaml → Create snackynerds namespace
4. kubectl apply deployment.yaml → Create/update deployment with 2 replicas
5. kubectl apply service.yaml → Create/update LoadBalancer service
6. kubectl rollout status → Wait until both pods are Running + Ready
7. kubectl get svc → Get LoadBalancer DNS → Print URL
```

**Key takeaway:** Kubernetes deployments are **declarative** — you describe the desired state (YAML), and Kubernetes figures out how to get there. You say "I want 2 replicas," not "start pod 1, then start pod 2."

---

## 🏗 What We Actually Built (Summary)

```
┌────────────────────────────────────────────────────────────────┐
│                    GitHub Repository                           │
│                                                                │
│  Push to main ──► GitHub Actions Pipeline                      │
│                   │                                            │
│                   ├── Phase 1: Test (Jest + Vitest)             │
│                   │   └── Upload JUnit reports                 │
│                   │                                            │
│                   ├── Phase 2: Terraform                        │
│                   │   ├── S3 Bucket (versioned, encrypted)     │
│                   │   ├── ECR Repository                       │
│                   │   ├── ECS Cluster + Service                │
│                   │   ├── EKS Cluster + Node Group             │
│                   │   └── Security Groups                      │
│                   │                                            │
│                   ├── Phase 3: Docker                           │
│                   │   ├── Build React client                   │
│                   │   ├── Build multi-stage server image       │
│                   │   └── Push to ECR                          │
│                   │                                            │
│                   └── Phase 4: Deploy (parallel)                │
│                       ├── ECS: Update task → Rolling deploy    │
│                       └── EKS: kubectl apply → 2 replica pods  │
│                                                                │
│  Result:                                                       │
│    ECS → http://<IP>:5001                                      │
│    EKS → http://<LB-DNS>:5001                                  │
└────────────────────────────────────────────────────────────────┘
```

---

## 🧪 Skills Demonstrated

| Skill | Evidence |
|-------|---------|
| **CI/CD Pipeline Design** | 5-job pipeline with parallel deploy targets |
| **Infrastructure as Code** | 10 Terraform files provisioning ECS + EKS + S3 + ECR |
| **Containerization** | Multi-stage Dockerfile with security best practices |
| **Cloud Deployment (ECS)** | ECS Fargate with rolling updates and health checks |
| **Cloud Deployment (EKS)** | Kubernetes with 2 replicas, probes, resource limits |
| **Kubernetes** | Namespaces, Deployments, Services, liveness/readiness probes |
| **Security** | Non-root container, encrypted S3, blocked public access, IAM roles |
| **Testing** | Unit + integration tests with automated report generation |
| **Automation** | Zero manual steps from push to production |

---

## 📖 Glossary

| Term | Plain English |
|------|-------------|
| **CI/CD** | Automatically test and deploy code when you push |
| **Terraform** | Write code that creates cloud infrastructure |
| **Docker** | Package your app so it runs the same everywhere |
| **ECR** | AWS's private Docker image storage |
| **ECS** | AWS service that runs Docker containers |
| **Fargate** | ECS mode where AWS manages the servers for you |
| **EKS** | AWS's managed Kubernetes service |
| **Kubernetes (K8s)** | Industry-standard container orchestration platform |
| **Pod** | Smallest deployable unit in Kubernetes (one or more containers) |
| **Deployment** | Manages pods — ensures desired replicas are running |
| **Service** | Exposes pods to network traffic (internal or external) |
| **Namespace** | Isolated space within a Kubernetes cluster |
| **LoadBalancer** | Distributes traffic across multiple pods/containers |
| **Liveness Probe** | Health check — restarts container if it fails |
| **Readiness Probe** | Traffic check — stops sending traffic if not ready |
| **Resource Limits** | CPU/memory caps that prevent pods from starving others |
| **Node Group** | Pool of EC2 instances that run pods |
| **Task Definition** | ECS blueprint for a container (image, CPU, memory, ports) |
| **Security Group** | Firewall rules for what traffic is allowed |
| **IAM Role** | Permission set that defines what AWS services can do |
| **JUnit XML** | Standard format for test result reports |
| **Multi-stage build** | Dockerfile technique: build in one image, run in a smaller one |
| **Rolling deployment** | Update containers one at a time (zero downtime) |
| **Healthcheck** | Periodic test to verify a container is working |
| **kubectl** | CLI tool for interacting with Kubernetes clusters |
| **Artifact** | File saved from a CI job (test reports, build outputs) |

---

*Phase 2 + Phase 4 complete — ECS and EKS running in parallel from the same pipeline.* 🚀
