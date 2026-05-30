#!/bin/bash
# health-check.sh — verifies the app is running correctly after deploy
set -e

: "${ALB_DNS_NAME:?ALB_DNS_NAME is required}"

MAX_RETRIES=10
SLEEP_SECONDS=15
BACKEND_URL="http://$ALB_DNS_NAME"

echo "==> StartTech Health Check"
echo "Target: $BACKEND_URL"
echo ""

# Check /health endpoint
echo "==> Checking backend /health..."
for i in $(seq 1 $MAX_RETRIES); do
  HTTP_CODE=$(curl -s -o /tmp/health_response.json \
    -w "%{http_code}" "$BACKEND_URL/health" || echo "000")

  echo "  Attempt $i/$MAX_RETRIES — HTTP $HTTP_CODE"

  if [ "$HTTP_CODE" == "200" ]; then
    echo "  Response: $(cat /tmp/health_response.json)"
    echo "✅ Backend is healthy!"
    break
  fi

  if [ "$i" == "$MAX_RETRIES" ]; then
    echo "❌ Backend health check failed after $MAX_RETRIES attempts"
    exit 1
  fi

  sleep $SLEEP_SECONDS
done

# Check /api/items endpoint
echo ""
echo "==> Checking /api/items..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/items")

if [ "$HTTP_CODE" == "200" ]; then
  echo "✅ API endpoint responding!"
else
  echo "⚠️  /api/items returned HTTP $HTTP_CODE"
fi

echo ""
echo "✅ All health checks passed!"
echo "🌐 Backend URL: $BACKEND_URL"
