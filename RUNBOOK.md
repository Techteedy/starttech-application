# StartTech — Operations Runbook

This document covers how to operate, monitor, and troubleshoot the StartTech application.

---

## Checking if the App is Running

### 1. Check the backend health endpoint
```bash
curl http://<ALB_DNS_NAME>/health
# Expected response:
# {"status":"healthy","environment":"production","version":"1.0.0","timestamp":"..."}
```

### 2. Check EC2 instances are healthy in the ASG
- AWS Console → EC2 → Auto Scaling Groups → `starttech-backend-asg`
- All instances should show **InService** and **Healthy**

### 3. Check the frontend loads
- Open your CloudFront URL in a browser
- The StartTech homepage should load
- Click "API Status" — it should say "Backend is Healthy"

---

## Viewing Logs

### Via AWS Console
1. Go to **CloudWatch → Log Groups**
2. Open `/starttech/prod/backend`
3. Click on any log stream (named after instance IDs)

### Via AWS CLI
```bash
# Tail live logs
aws logs tail /starttech/prod/backend --follow

# Search for errors in the last hour
aws logs filter-log-events \
  --log-group-name /starttech/prod/backend \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s000)
```

### Via Log Insights (AWS Console)
Go to **CloudWatch → Logs Insights**, select `/starttech/prod/backend`, and run:
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50
```

---

## Deploying a New Version

### Automatic (recommended)
Just push your code to the `main` branch. GitHub Actions handles everything.

```bash
git add .
git commit -m "fix: update API response format"
git push origin main
# Watch the pipeline at: github.com/YOUR_USERNAME/starttech-application/actions
```

### Manual deploy
```bash
# Backend
export ECR_REPOSITORY_URL=<from terraform output>
export ASG_NAME=starttech-backend-asg
export AWS_REGION=us-east-1
bash scripts/deploy-backend.sh

# Frontend
export S3_BUCKET_NAME=<from terraform output>
export CLOUDFRONT_DISTRIBUTION_ID=<from terraform output>
export REACT_APP_API_URL=http://<ALB_DNS_NAME>
bash scripts/deploy-frontend.sh
```

---

## Rolling Back a Bad Deploy

### Find the last good image tag
```bash
# List recent images in ECR
aws ecr describe-images \
  --repository-name starttech-backend \
  --query 'sort_by(imageDetails, &imagePushedAt)[-5:].imageTags' \
  --output table
```

### Roll back to a previous tag
```bash
export AWS_REGION=us-east-1
export ECR_REPOSITORY_URL=<your-ecr-url>
export ASG_NAME=starttech-backend-asg
export ROLLBACK_TAG=41-abc1234   # the tag you want to roll back to
bash scripts/rollback.sh
```

---

## Common Problems & Fixes

### Problem: Backend returning 502 Bad Gateway
The ALB can't reach the EC2 instances.

**Check:**
1. EC2 instances in ASG — are they InService?
2. Target group health checks — any unhealthy targets?
3. Is Docker running on the instance?

```bash
# SSH into an EC2 instance (if you have a key pair configured)
# Then check Docker:
docker ps                          # is the container running?
docker logs starttech-backend      # any crash errors?
```

### Problem: Frontend shows blank page or old version
CloudFront is serving a cached version.

**Fix:**
```bash
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
  --paths "/*"
```

### Problem: GitHub Actions pipeline fails on "Push to ECR"
AWS credentials may be expired or missing permissions.

**Check:**
- Go to GitHub → Settings → Secrets → confirm `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set
- Check the IAM user has `AmazonEC2ContainerRegistryFullAccess` policy

### Problem: Terraform apply fails with "Access Denied"
```bash
# Verify your AWS credentials work
aws sts get-caller-identity

# Make sure the IAM user has the right policies attached
```

### Problem: EC2 instances launching but app not starting
Check the EC2 user data script ran correctly:

```bash
# On the EC2 instance, check the cloud-init log
cat /var/log/cloud-init-output.log
```

---

## Scaling Manually

```bash
# Temporarily increase to 3 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-backend-asg \
  --desired-capacity 3

# Scale back down to 1 (e.g. to save costs)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-backend-asg \
  --desired-capacity 1
```

---

## Tearing Down (Destroying All Infrastructure)

```bash
cd starttech-infra/terraform
terraform destroy
# Type 'yes' when prompted
# This will DELETE everything — S3, EC2, Redis, ALB, etc.
```

> ⚠️ Make sure you have backed up any important data from MongoDB first.
