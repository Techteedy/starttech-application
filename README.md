# StartTech Application

A production-grade full-stack application with a complete CI/CD pipeline on AWS.

## What's In This Repo

```
starttech-application/
├── .github/workflows/
│   ├── frontend-ci-cd.yml     # React → S3 pipeline
│   └── backend-ci-cd.yml      # Golang → EC2 pipeline
├── frontend/                  # React application
├── backend/                   # Golang REST API
└── scripts/                   # Deploy, health-check, rollback scripts
```

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React 18, React Router, Axios |
| Backend | Golang 1.21, Gin framework |
| Database | MongoDB Atlas |
| Cache | Redis (AWS ElastiCache) |
| Infrastructure | AWS (EC2, S3, CloudFront, ALB, ASG) |
| CI/CD | GitHub Actions |
| Containers | Docker, AWS ECR |

---

## Local Development Setup

### Prerequisites
- Node.js 18+
- Go 1.21+
- Docker
- MongoDB running locally (or Atlas connection string)
- Redis running locally

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/starttech-application.git
cd starttech-application
```

### 2. Run the Backend
```bash
cd backend
cp .env.example .env        # fill in your local values
go mod download
go run ./cmd/server
# Server starts on http://localhost:8080
```

### 3. Run the Frontend
```bash
cd frontend
cp .env.example .env.local  # set REACT_APP_API_URL=http://localhost:8080
npm install
npm start
# App opens on http://localhost:3000
```

### 4. Test everything works
- Open http://localhost:3000
- Click "API Status" — it should show "Backend is Healthy"

---

## Running Tests

### Frontend tests
```bash
cd frontend
npm test
```

### Backend tests
```bash
cd backend
go test ./... -v
```

---

## CI/CD Pipeline

### Frontend Pipeline (frontend-ci-cd.yml)
Triggers when you push changes to the `frontend/` folder.

```
Push to main
    ↓
Install dependencies → Run tests → Security audit → Build React
    ↓
Upload to S3 → Invalidate CloudFront cache
```

### Backend Pipeline (backend-ci-cd.yml)
Triggers when you push changes to the `backend/` folder.

```
Push to main
    ↓
Run Go tests → Vulnerability scan → Build Docker image → Scan image
    ↓
Push to ECR → Rolling deploy to EC2 ASG → Smoke test
```

---

## Required GitHub Secrets

Go to: **Settings → Secrets and variables → Actions**

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key |
| `S3_BUCKET_NAME` | S3 bucket name (from Terraform output) |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront ID (from Terraform output) |
| `CLOUDFRONT_DOMAIN` | CloudFront domain name |
| `REACT_APP_API_URL` | Backend ALB DNS name |
| `ECR_REPOSITORY_URL` | ECR repo URL (from Terraform output) |
| `ASG_NAME` | Auto Scaling Group name |
| `ALB_DNS_NAME` | Load balancer DNS name |
| `MONGO_URI` | MongoDB Atlas connection string |

---

## Manual Deployment (without pipeline)

```bash
# Deploy frontend manually
export S3_BUCKET_NAME=your-bucket
export CLOUDFRONT_DISTRIBUTION_ID=your-cf-id
export REACT_APP_API_URL=http://your-alb-dns
bash scripts/deploy-frontend.sh

# Deploy backend manually
export ECR_REPOSITORY_URL=your-ecr-url
export ASG_NAME=starttech-backend-asg
bash scripts/deploy-backend.sh

# Check health after deploy
export ALB_DNS_NAME=your-alb-dns
bash scripts/health-check.sh

# Rollback to a previous version
export ROLLBACK_TAG=42-a1b2c3d   # image tag to roll back to
bash scripts/rollback.sh
```
