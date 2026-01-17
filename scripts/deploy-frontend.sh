#!/bin/bash
set -e

echo "=== Deploying Frontend to S3 ==="

# Check environment variables
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "ERROR: AWS credentials not set!"
  exit 1
fi

if [ -z "$S3_BUCKET_NAME" ]; then
  echo "ERROR: S3_BUCKET_NAME not set!"
  exit 1
fi

# Build frontend
echo "Building frontend..."
cd frontend
npm ci
npm run build

# Sync to S3
echo "Syncing to S3 bucket: $S3_BUCKET_NAME"
aws s3 sync dist/ s3://$S3_BUCKET_NAME \
  --delete \
  --cache-control "max-age=31536000,public"

# Invalidate CloudFront cache if distribution ID is provided
if [ -n "$CLOUDFRONT_DIST_ID" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_DIST_ID \
    --paths "/*"
fi

echo "Frontend deployment complete!"
echo "S3 Bucket: $S3_BUCKET_NAME"
if [ -n "$CLOUDFRONT_DIST_ID" ]; then
  echo "CloudFront Distribution ID: $CLOUDFRONT_DIST_ID"
fi
