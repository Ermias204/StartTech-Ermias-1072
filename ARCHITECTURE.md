# System Architecture

## Overview

The StartTech MuchToDo application is a full-stack task management application with the following architecture:
Users → CloudFront CDN → S3 (Frontend) → ALB → EC2 Auto Scaling Group (Backend)
↓
ElastiCache Redis
↓
MongoDB Atlas

text

## Components

### 1. Frontend (React + TypeScript + Vite)
- **Framework:** React 18 with TypeScript
- **Build Tool:** Vite for fast builds and HMR
- **State Management:** React Context API
- **HTTP Client:** Axios for API calls
- **Deployment:** AWS S3 with CloudFront CDN

### 2. Backend API (Golang)
- **Framework:** Standard Go HTTP package
- **Structure:** Clean Architecture with internal packages
- **API Design:** RESTful endpoints
- **Authentication:** JWT-based authentication
- **Deployment:** Docker containers on EC2 Auto Scaling Group

### 3. Infrastructure (Terraform)
- **VPC:** Multi-AZ deployment in eu-west-1
- **Compute:** Auto Scaling Group with t3.micro instances
- **Load Balancing:** Application Load Balancer with health checks
- **Storage:** S3 for frontend, ECR for Docker images
- **Caching:** ElastiCache Redis for sessions and caching
- **Networking:** Security groups, route tables, NAT Gateway

### 4. Database (MongoDB Atlas)
- **Type:** Document database
- **Service:** MongoDB Atlas (managed)
- **Location:** AWS eu-west-1 region
- **Access:** From EC2 instances via VPC peering or public endpoint

### 5. Caching (Amazon ElastiCache Redis)
- **Type:** Redis 7.x
- **Node Type:** cache.t3.micro
- **Purpose:** Session storage, API response caching
- **Location:** Private subnets within VPC

### 6. Content Delivery (Amazon CloudFront)
- **Origin:** S3 bucket with static website hosting
- **SSL/TLS:** AWS Certificate Manager (ACM)
- **Caching:** Edge locations worldwide
- **Compression:** Gzip and Brotli support

## Data Flow

1. **User Request:**
   - User accesses application via domain name
   - DNS routes to CloudFront distribution

2. **Frontend Delivery:**
   - CloudFront checks edge cache for static assets
   - Cache miss fetches from S3 origin
   - React application loads in browser

3. **API Request:**
   - Frontend makes API call to backend endpoint
   - Request goes to Application Load Balancer
   - ALB routes to healthy EC2 instance

4. **Backend Processing:**
   - Golang API receives request
   - Checks Redis cache for data (if applicable)
   - Cache miss queries MongoDB database
   - Processes business logic
   - Returns JSON response

5. **Response Delivery:**
   - Response flows back through ALB to frontend
   - Frontend updates UI with data
   - User sees updated information

## Security Architecture

### Network Security
- **VPC Design:** Public and private subnets
- **Security Groups:** Least privilege access between components
- **NACLs:** Additional network layer protection
- **SSL/TLS:** All external traffic encrypted

### Application Security
- **Authentication:** JWT tokens with expiration
- **Authorization:** Role-based access control
- **Input Validation:** Server-side validation
- **CORS:** Properly configured for frontend domain

### Infrastructure Security
- **IAM Roles:** Least privilege for EC2 instances
- **Secrets Management:** GitHub Secrets for CI/CD
- **Encryption:** Data encrypted at rest and in transit
- **Monitoring:** CloudWatch logs and alarms

## Scalability Design

### Horizontal Scaling
- **Frontend:** S3 + CloudFront automatically scales
- **Backend:** Auto Scaling Group adds/removes EC2 instances
- **Database:** MongoDB Atlas auto-scaling
- **Cache:** Redis cluster can be scaled vertically

### Load Distribution
- **CDN:** CloudFront distributes global traffic
- **ALB:** Distributes traffic across EC2 instances
- **Health Checks:** Automatic unhealthy instance replacement
- **Auto Scaling:** Based on CPU utilization metrics

## Monitoring and Observability

### Logging
- **Application Logs:** CloudWatch Logs via AWS SDK
- **Access Logs:** ALB access logs to S3
- **Error Logs:** Structured error logging in Go

### Metrics
- **Infrastructure:** CloudWatch metrics for EC2, ALB, Redis
- **Application:** Custom business metrics
- **Synthetic Monitoring:** Health check endpoints

### Alerts
- **Infrastructure:** CPU, memory, disk alerts
- **Application:** Error rate, response time alerts
- **Business:** User activity, transaction alerts

## Deployment Strategy

### Frontend Deployment
- **Method:** Blue-green deployment via S3 versioning
- **Rollback:** S3 object version restoration
- **Testing:** Canary testing with route53 weighted routing

### Backend Deployment
- **Method:** Rolling update with Auto Scaling Group
- **Health Checks:** Instance replacement only when healthy
- **Rollback:** Launch template version reversion

## Cost Optimization

### Resource Sizing
- **Development:** t3.micro instances
- **Production:** Auto-scaling based on load
- **Storage:** S3 lifecycle policies for old files

### Reserved Instances
- **EC2:** Reserved instances for predictable workloads
- **ElastiCache:** Reserved nodes for 1-year commitment
- **Savings Plans:** Flexible pricing for variable workloads

## Disaster Recovery

### Backup Strategy
- **Database:** MongoDB Atlas daily backups
- **Redis:** Periodic snapshots
- **Application Code:** GitHub repository
- **Infrastructure:** Terraform state in S3 with versioning

### Recovery Objectives
- **RTO (Recovery Time Objective):** 2 hours
- **RPO (Recovery Point Objective):** 1 hour
- **Process:** Terraform apply from backup state
