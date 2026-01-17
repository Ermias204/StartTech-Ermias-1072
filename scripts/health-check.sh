#!/bin/bash
set -e

echo "=== Health Check ==="

# Check if ALB DNS is provided
if [ -z "$ALB_DNS_NAME" ]; then
  echo "ERROR: ALB_DNS_NAME not set!"
  exit 1
fi

# Health check endpoint
HEALTH_URL="http://$ALB_DNS_NAME/health"

echo "Checking health at: $HEALTH_URL"

# Try health check with retries
MAX_RETRIES=10
RETRY_DELAY=10

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i/$MAX_RETRIES..."
  
  if curl -s -f $HEALTH_URL > /dev/null; then
    echo "Health check PASSED!"
    exit 0
  fi
  
  if [ $i -lt $MAX_RETRIES ]; then
    echo "Health check failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  fi
done

echo "Health check FAILED after $MAX_RETRIES attempts"
exit 1
