#!/bin/bash
# deploy-frontend.sh — builds and deploys React app to S3 + CloudFront
set -e

echo "==> StartTech Frontend Deployment"

# Required environment variables
: "${S3_BUCKET_NAME:?S3_BUCKET_NAME is required}"
: "${CLOUDFRONT_DISTRIBUTION_ID:?CLOUDFRONT_DISTRIBUTION_ID is required}"
: "${REACT_APP_API_URL:?REACT_APP_API_URL is required}"

FRONTEND_DIR="$(dirname "$0")/../frontend"

echo "S3 Bucket  : $S3_BUCKET_NAME"
echo "CloudFront : $CLOUDFRONT_DISTRIBUTION_ID"
echo "API URL    : $REACT_APP_API_URL"
echo ""

# Step 1: Install dependencies
echo "==> Installing dependencies..."
cd "$FRONTEND_DIR"
npm ci

# Step 2: Run tests
echo "==> Running tests..."
CI=true npm test

# Step 3: Build
echo "==> Building production bundle..."
REACT_APP_API_URL="$REACT_APP_API_URL" \
REACT_APP_ENV="production" \
npm run build

# Step 4: Upload to S3
echo "==> Syncing to S3..."
# Long-lived cache for hashed assets
aws s3 sync build/ "s3://$S3_BUCKET_NAME" \
  --delete \
  --cache-control "public, max-age=31536000" \
  --exclude "index.html"

# No cache for index.html
aws s3 cp build/index.html "s3://$S3_BUCKET_NAME/index.html" \
  --cache-control "no-cache, no-store, must-revalidate"

# Step 5: Invalidate CloudFront
echo "==> Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
  --paths "/*"

echo ""
echo "✅ Frontend deployed successfully!"
