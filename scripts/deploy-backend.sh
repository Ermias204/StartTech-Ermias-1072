#!/bin/bash
set -e

echo "=== Deploying Backend to ECR ==="

# Check environment variables
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "ERROR: AWS credentials not set!"
  exit 1
fi

if [ -z "$ECR_REPOSITORY" ]; then
  echo "ERROR: ECR_REPOSITORY not set!"
  exit 1
fi

# Get ECR registry URL
REGION=${AWS_REGION:-eu-west-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build Docker image
echo "Building Docker image..."
cd backend/MuchToDo
docker build -t $ECR_REPOSITORY:latest .
docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest

# Push to ECR
echo "Pushing to ECR..."
docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

echo "Backend deployment complete!"
echo "Image: $ECR_REGISTRY/$ECR_REPOSITORY:latest"
echo ""
echo "Next steps:"
echo "1. Update Auto Scaling Group launch template to use new image"
echo "2. Terminate old instances to force redeployment"
