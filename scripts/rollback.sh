#!/bin/bash
# rollback.sh — rolls back to the previous Docker image if deploy fails
set -e

echo "==> StartTech Rollback"

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_REPOSITORY_URL:?ECR_REPOSITORY_URL is required}"
: "${ASG_NAME:?ASG_NAME is required}"
: "${ROLLBACK_TAG:?ROLLBACK_TAG is required (the image tag to roll back to)}"

echo "Rolling back to image tag: $ROLLBACK_TAG"
echo ""

# Verify the rollback image exists in ECR
echo "==> Verifying rollback image exists in ECR..."
aws ecr describe-images \
  --repository-name starttech-backend \
  --image-ids imageTag="$ROLLBACK_TAG" \
  --region "$AWS_REGION" > /dev/null

echo "✅ Image $ROLLBACK_TAG found in ECR"

# Re-tag the old image as latest
echo "==> Re-tagging $ROLLBACK_TAG as latest..."
MANIFEST=$(aws ecr batch-get-image \
  --repository-name starttech-backend \
  --image-ids imageTag="$ROLLBACK_TAG" \
  --query 'images[0].imageManifest' \
  --output text)

aws ecr put-image \
  --repository-name starttech-backend \
  --image-tag latest \
  --image-manifest "$MANIFEST"

# Trigger rolling deploy with rollback image
echo "==> Triggering rollback deploy on ASG..."
REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 60}' \
  --query 'InstanceRefreshId' \
  --output text)

echo "Rollback instance refresh ID: $REFRESH_ID"

# Wait for completion
for i in $(seq 1 20); do
  STATUS=$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "$ASG_NAME" \
    --instance-refresh-ids "$REFRESH_ID" \
    --query 'InstanceRefreshes[0].Status' \
    --output text)

  echo "  [$i/20] Status: $STATUS"

  if [ "$STATUS" == "Successful" ]; then
    echo ""
    echo "✅ Rollback to $ROLLBACK_TAG complete!"
    exit 0
  elif [ "$STATUS" == "Failed" ] || [ "$STATUS" == "Cancelled" ]; then
    echo "❌ Rollback $STATUS — check AWS Console immediately"
    exit 1
  fi

  sleep 30
done
