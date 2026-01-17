# StartTech Full Stack Application

This repository contains the React frontend and Golang backend for the StartTech MuchToDo application.

## Repository Structure

StartTech-Ermias-1072/
├── .github/workflows/
│ ├── frontend-ci-cd.yml # Frontend CI/CD pipeline
│ └── backend-ci-cd.yml # Backend CI/CD pipeline
├── frontend/ # React frontend (Vite + TypeScript)
│ ├── src/ # Source code
│ ├── public/ # Static assets
│ ├── package.json # Dependencies and scripts
│ └── vite.config.ts # Build configuration
├── backend/ # Golang backend API
│ └── MuchToDo/ # Go module
│ ├── cmd/api/ # Application entry point
│ ├── internal/ # Internal packages
│ ├── go.mod # Go modules
│ └── Dockerfile # Container configuration
├── scripts/ # Deployment scripts
│ ├── deploy-frontend.sh # Manual frontend deployment
│ ├── deploy-backend.sh # Manual backend deployment
│ ├── health-check.sh # Health check script
│ └── rollback.sh # Rollback instructions
└── README.md # This file

text

## CI/CD Pipelines

### Frontend Pipeline

- **Trigger:** Changes to `frontend/**` directory
- **Steps:**
  1. Install Node.js dependencies
  2. Run linter and tests
  3. Security audit (npm audit)
  4. Build production bundle with Vite
  5. Deploy to S3 bucket
  6. Invalidate CloudFront cache

### Backend Pipeline

- **Trigger:** Changes to `backend/**` directory
- **Steps:**
  1. Install Go dependencies
  2. Run unit tests
  3. Security scanning (Trivy)
  4. Code linting (golangci-lint)
  5. Build Docker image
  6. Scan Docker image for vulnerabilities
  7. Push to Amazon ECR

## Required GitHub Secrets

Add these secrets in GitHub Repository Settings → Secrets and variables → Actions:

```bash
AWS_ACCESS_KEY_ID           # AWS IAM user access key
AWS_SECRET_ACCESS_KEY       # AWS IAM user secret key
AWS_REGION                  # eu-west-1
ECR_REPOSITORY              # starttech-backend
S3_BUCKET_NAME              # starttech-frontend-[initials]-[id]-app
CLOUDFRONT_DIST_ID          # CloudFront Distribution ID (from infrastructure)
MONGO_CONNECTION_STRING     # MongoDB Atlas connection string
REDIS_ENDPOINT              # ElastiCache Redis endpoint (from infrastructure)
ALB_DNS_NAME                # Application Load Balancer DNS (from infrastructure)
Manual Deployment
Frontend
bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export S3_BUCKET_NAME="your-bucket"
export CLOUDFRONT_DIST_ID="your-dist-id"

./scripts/deploy-frontend.sh
Backend
bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export ECR_REPOSITORY="starttech-backend"

./scripts/deploy-backend.sh
Health Check
bash
export ALB_DNS_NAME="your-alb-dns"
./scripts/health-check.sh
Local Development
Frontend
bash
cd frontend
npm install
npm run dev
Backend
bash
cd backend/MuchToDo
go run cmd/api/main.go
Infrastructure
The infrastructure is managed in a separate repository: StartTech-infra-Ermias-1072

See the infrastructure repository for Terraform configurations and setup instructions.
```
