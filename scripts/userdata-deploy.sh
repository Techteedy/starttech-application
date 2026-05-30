#!/bin/bash
# userdata-deploy.sh
# This script runs on each EC2 instance when ASG launches a new one.
# It pulls the latest Docker image from ECR and starts the container.
set -e

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ECR_REPO="${ECR_REPOSITORY_URL}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
LOG_GROUP="/starttech/prod/backend"

# Log in to ECR
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ECR_REPO"

# Stop old container if running
docker stop starttech-backend 2>/dev/null || true
docker rm   starttech-backend 2>/dev/null || true

# Pull latest image
docker pull "$ECR_REPO:$IMAGE_TAG"

# Start new container with CloudWatch logging
docker run -d \
  --name starttech-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e APP_ENV=production \
  -e APP_VERSION="$IMAGE_TAG" \
  -e MONGO_URI="$MONGO_URI" \
  -e REDIS_ADDR="$REDIS_ADDR" \
  --log-driver=awslogs \
  --log-opt awslogs-region="$REGION" \
  --log-opt awslogs-group="$LOG_GROUP" \
  --log-opt awslogs-stream="$INSTANCE_ID" \
  "$ECR_REPO:$IMAGE_TAG"

echo "StartTech backend $IMAGE_TAG started on $INSTANCE_ID"
