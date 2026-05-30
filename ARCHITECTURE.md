# StartTech — Architecture Documentation

## System Overview

StartTech is a full-stack web application deployed on AWS with a fully automated CI/CD pipeline. All infrastructure is managed as code using Terraform.

```
                        ┌─────────────────────────────────────┐
                        │           INTERNET USERS             │
                        └──────────────┬──────────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
                    │         AWS CloudFront (CDN)         │
                    │   Global edge — serves React app     │
                    └──────────────────┬──────────────────┘
                                       │
                    ┌──────────────────▼──────────────────┐
                    │            AWS S3 Bucket             │
                    │    Stores built React static files   │
                    └─────────────────────────────────────┘

                    ┌──────────────────────────────────────┐
                    │    Application Load Balancer (ALB)   │
                    │  Receives API calls, health checks   │
                    └────────┬──────────────┬─────────────┘
                             │              │
               ┌─────────────▼──┐    ┌──────▼─────────────┐
               │  EC2 Instance 1 │    │  EC2 Instance 2    │
               │  Golang :8080   │    │  Golang :8080      │
               └────────┬───────┘    └────────┬───────────┘
                        │                     │
               ┌────────▼─────────────────────▼───────────┐
               │         Auto Scaling Group (ASG)          │
               │  Scales between 1–4 instances on CPU %   │
               └────────┬─────────────────────────────────┘
                        │
          ┌─────────────┴──────────────┐
          │                            │
┌─────────▼──────────┐    ┌────────────▼──────────┐
│  ElastiCache Redis  │    │    MongoDB Atlas       │
│  Sessions & cache   │    │  Persistent data store │
└─────────────────────┘    └───────────────────────┘
```

---

## Network Architecture

All resources live inside a custom **VPC (10.0.0.0/16)**:

| Subnet Type | CIDR | Contains |
|---|---|---|
| Public Subnet 1 (AZ-a) | 10.0.1.0/24 | ALB |
| Public Subnet 2 (AZ-b) | 10.0.2.0/24 | ALB (multi-AZ) |
| Private Subnet 1 (AZ-a) | 10.0.10.0/24 | EC2, Redis |
| Private Subnet 2 (AZ-b) | 10.0.11.0/24 | EC2, Redis |

EC2 instances and Redis sit in **private subnets** — they are never directly reachable from the internet. All traffic flows through the ALB.

---

## Security Design

### Security Groups (firewall rules)

```
Internet → ALB (port 80, 443 open to 0.0.0.0/0)
ALB → EC2 (port 8080, only from ALB security group)
EC2 → Redis (port 6379, only from EC2 security group)
```

### IAM (permissions)
EC2 instances have a role with **only** the permissions they need:
- `CloudWatchAgentServerPolicy` — write logs to CloudWatch
- `AmazonEC2ContainerRegistryReadOnly` — pull Docker images from ECR

### Secrets
- All secrets stored in **GitHub Secrets** (never in code)
- MongoDB URI passed as environment variable to containers
- `terraform.tfvars` is gitignored — never committed

---

## CI/CD Pipeline Flow

### Frontend Pipeline
```
Git push (frontend/ changes)
    → Install Node deps
    → Run React unit tests
    → npm audit (security scan)
    → Build production bundle (with env vars injected)
    → aws s3 sync → S3 bucket
    → CloudFront invalidation (clears CDN cache)
```

### Backend Pipeline
```
Git push (backend/ changes)
    → go test (unit tests)
    → go vet (code quality)
    → govulncheck (vulnerability scan)
    → docker build (multi-stage, non-root user)
    → Trivy scan (Docker image vulnerabilities)
    → docker push → ECR
    → ASG instance refresh (rolling deploy)
    → Smoke test on ALB /health endpoint
```

### Infrastructure Pipeline
```
Git push (terraform/ changes)
    → terraform fmt check
    → terraform validate
    → terraform plan (shown as PR comment)
    → [manual approval required]
    → terraform apply
```

---

## Auto Scaling

The backend scales automatically based on CPU:

| Condition | Action |
|---|---|
| CPU > 80% for 4 minutes | Add 1 EC2 instance |
| CPU < 20% for 15 minutes | Remove 1 EC2 instance |
| Minimum instances | 1 |
| Maximum instances | 4 |

Rolling deployments replace instances **one at a time**, keeping at least 50% healthy during deploys — zero downtime.

---

## Monitoring

All EC2 container logs are sent to **CloudWatch Logs** automatically via the Docker `awslogs` driver.

| Log Group | Contents |
|---|---|
| `/starttech/prod/backend` | Golang application logs (requests, errors) |
| `/starttech/prod/frontend` | CloudFront access logs |

### Alarms
| Alarm | Threshold | Action |
|---|---|---|
| High CPU | > 80% | Scale up |
| Low CPU | < 20% | Scale down |
| ALB 5xx errors | > 10/minute | Notify |
| Unhealthy hosts | > 0 | Notify immediately |
