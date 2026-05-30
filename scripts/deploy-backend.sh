#!/bin/bash
# deploy-backend.sh — builds Docker image, pushes to ECR, triggers rolling deploy
set -e

echo "==> StartTech Backend Deployment"

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_REPOSITORY_URL:?ECR_REPOSITORY_URL is required}"
: "${ASG_NAME:?ASG_NAME is required}"

IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}"
BACKEND_DIR="$(dirname "$0")/../backend"

echo "ECR Repo   : $ECR_REPOSITORY_URL"
echo "Image Tag  : $IMAGE_TAG"
echo "ASG Name   : $ASG_NAME"
echo ""

# Step 1: Run tests
echo "==> Running tests..."
cd "$BACKEND_DIR"
go test ./... -v

# Step 2: Log in to ECR
echo "==> Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REPOSITORY_URL"

# Step 3: Build Docker image
echo "==> Building Docker image..."
docker build \
  --build-arg APP_VERSION="$IMAGE_TAG" \
  -t "$ECR_REPOSITORY_URL:$IMAGE_TAG" \
  -t "$ECR_REPOSITORY_URL:latest" \
  .

# Step 4: Push to ECR
echo "==> Pushing image to ECR..."
docker push "$ECR_REPOSITORY_URL:$IMAGE_TAG"
docker push "$ECR_REPOSITORY_URL:latest"

# Step 5: Trigger rolling update on ASG
echo "==> Triggering rolling deployment on ASG..."
REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}' \
  --query 'InstanceRefreshId' \
  --output text)

echo "Instance refresh ID: $REFRESH_ID"

# Step 6: Wait for completion
echo "==> Waiting for deployment to complete..."
for i in $(seq 1 30); do
  STATUS=$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "$ASG_NAME" \
    --instance-refresh-ids "$REFRESH_ID" \
    --query 'InstanceRefreshes[0].Status' \
    --output text)

  echo "  [$i/30] Status: $STATUS"

  if [ "$STATUS" == "Successful" ]; then
    echo "✅ Deployment complete!"
    exit 0
  elif [ "$STATUS" == "Failed" ] || [ "$STATUS" == "Cancelled" ]; then
    echo "❌ Deployment $STATUS — check AWS Console"
    exit 1
  fi

  sleep 30
done

echo "⚠️  Timed out waiting — check AWS Console manually"
exit 1
