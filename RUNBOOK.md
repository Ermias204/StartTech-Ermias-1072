# Operations Runbook

## Emergency Contacts
- **Primary DevOps Engineer:** Ermias
- **On-call Schedule:** Monday-Friday 9AM-6PM

## Quick Reference

### Important URLs
- **Application:** https://[your-cloudfront-distribution].cloudfront.net
- **GitHub Repository:** https://github.com/[your-username]/StartTech-[name]-[id]
- **AWS Console:** https://eu-west-1.console.aws.amazon.com
- **MongoDB Atlas:** https://cloud.mongodb.com
- **CloudWatch Dashboard:** https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=starttech-production-dashboard

### Critical Secrets Location
- **GitHub Secrets:** Repository Settings → Secrets and variables → Actions
- **AWS Credentials:** IAM User: starttech-cicd-user
- **Database Connection:** MongoDB Atlas Cluster → Connect → Connection String

## Common Issues and Solutions

### Issue 1: Frontend Not Loading (CloudFront/S3)
**Symptoms:**
- CloudFront returns 403/404 errors
- S3 bucket shows "Access Denied"
- Blank page or application errors

**Diagnosis:**
```bash
# Check CloudFront distribution
aws cloudfront get-distribution --id $CLOUDFRONT_DIST_ID

# Check S3 bucket policy
aws s3api get-bucket-policy --bucket $S3_BUCKET_NAME

# List S3 bucket contents
aws s3 ls s3://$S3_BUCKET_NAME --recursive
Resolution:

Verify CloudFront origin points to correct S3 bucket

Check S3 bucket policy allows CloudFront OAI

Invalidate CloudFront cache:

bash
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DIST_ID --paths "/*"
Verify files exist in S3:

bash
aws s3 cp s3://$S3_BUCKET_NAME/index.html /dev/null
Issue 2: Backend API Unavailable
Symptoms:

ALB returns 502/503/504 errors

Health checks failing

No healthy instances in target group

Diagnosis:

bash
# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names starttech-production-tg --query "TargetGroups[0].TargetGroupArn" --output text)

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names starttech-production-asg

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=starttech-production-backend" --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PrivateIpAddress}"
Resolution:

SSH to EC2 instance (use bastion if in private subnet):

bash
ssh -i key.pem ec2-user@[INSTANCE_IP]
Check Docker containers:

bash
docker ps
docker logs [CONTAINER_ID]
Check application logs:

bash
sudo journalctl -u backend.service -f
Check system resources:

bash
top
df -h
free -h
Issue 3: Database Connection Errors
Symptoms:

Backend logs show MongoDB connection failures

500 errors on database operations

"Connection refused" or "Timeout" errors

Diagnosis:

bash
# Test connectivity from EC2
ssh -i key.pem ec2-user@[INSTANCE_IP]
telnet [MONGODB_HOST] 27017
nc -zv [MONGODB_HOST] 27017
Resolution:

Check MongoDB Atlas cluster status

Verify network access from AWS VPC

Check connection string in GitHub Secrets

Verify database user credentials

Issue 4: Redis Connection Errors
Symptoms:

Backend logs show Redis connection failures

Cache operations timing out

Session data lost

Diagnosis:

bash
# Check ElastiCache status
aws elasticache describe-cache-clusters --cache-cluster-id starttech-production-redis --show-cache-node-info

# Test Redis connectivity
redis-cli -h [REDIS_ENDPOINT] -p 6379 ping
Resolution:

Check ElastiCache cluster is in "available" state

Verify security group allows EC2 access

Check Redis endpoint in GitHub Secrets

Restart Redis if needed (causes data loss)

Deployment Procedures
Normal Deployment Process
Frontend:

Code merged to main branch

GitHub Actions builds and deploys to S3

CloudFront cache invalidated automatically

Verify deployment at CloudFront URL

Backend:

Code merged to main branch

GitHub Actions builds Docker image and pushes to ECR

Auto Scaling Group launch template updated with new image

New instances launched, old instances terminated

Verify health checks pass

Manual Deployment
Frontend:

bash
cd frontend
npm ci
npm run build
aws s3 sync dist/ s3://$S3_BUCKET_NAME --delete --cache-control "max-age=31536000,public"
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DIST_ID --paths "/*"
Backend:

bash
cd backend/MuchToDo
docker build -t $ECR_REPOSITORY:latest .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com
docker tag $ECR_REPOSITORY:latest $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/$ECR_REPOSITORY:latest
docker push $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/$ECR_REPOSITORY:latest
Monitoring Procedures
Daily Checks
CloudWatch Dashboard: Review key metrics

Error Rates: Check for 5XX errors in ALB

Response Times: Ensure < 2 seconds average

Instance Count: Verify desired capacity maintained

Weekly Checks
Security Updates: Check for OS updates on AMI

Cost Review: Review AWS Cost Explorer

Backup Verification: Confirm MongoDB backups

Log Retention: Review and archive old logs

Maintenance Windows
Weekly Maintenance (Sunday 02:00-04:00 UTC)
Apply security patches to EC2 instances

Rotate credentials if needed

Clean up old Docker images from ECR

Review and update CloudWatch alarms

Monthly Maintenance (First Sunday)
Update Terraform modules to latest versions

Update AMI IDs for EC2 instances

Review IAM policies and permissions

Conduct security audit

Emergency Procedures
Complete System Outage
Assessment: Identify root cause (network, database, application)

Communication: Notify stakeholders of outage

Recovery: Follow issue-specific resolution above

Post-mortem: Document root cause and preventive measures

Data Corruption
Isolate: Stop traffic to affected component

Restore: Use latest backup from MongoDB Atlas

Validate: Test data integrity

Resume: Gradually restore traffic

Security Breach
Contain: Isolate affected systems

Investigate: Preserve logs for forensics

Rotate: Immediately rotate all credentials

Report: Follow company security incident protocol

Rollback Procedures
Frontend Rollback
Identify previous working version in S3 version history

Restore index.html and assets:

bash
aws s3api list-object-versions --bucket $S3_BUCKET_NAME --prefix index.html
aws s3api copy-object --bucket $S3_BUCKET_NAME --key index.html --copy-source "$S3_BUCKET_NAME/index.html?versionId=[VERSION_ID]"
Invalidate CloudFront cache

Verify rollback successful

Backend Rollback
Identify previous Docker image in ECR:

bash
aws ecr describe-images --repository-name $ECR_REPOSITORY --query "sort_by(imageDetails, &imagePushedAt)[-5:]"
Update launch template to use previous image

Terminate current instances to force redeployment

Verify health checks pass

Appendix
AWS CLI Commands Reference
List all resources:

bash
# EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=starttech"

# Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names starttech-production-asg

# Load Balancers
aws elbv2 describe-load-balancers --names starttech-production-alb

# CloudFront distributions
aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='starttech-production-cloudfront'].Id"
Useful Scripts
Health check all components:

bash
./scripts/health-check.sh

# Additional checks
aws elbv2 describe-target-health --target-group-arn [TARGET_GROUP_ARN]
aws elasticache describe-cache-clusters --cache-cluster-id starttech-production-redis
Quick deployment status:

bash
echo "Frontend:"
aws s3 ls s3://$S3_BUCKET_NAME/index.html
echo ""
echo "Backend:"
aws ecr describe-images --repository-name $ECR_REPOSITORY --query "imageDetails[0].imageTags"
echo ""
echo "Infrastructure:"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names starttech-production-asg --query "AutoScalingGroups[0].Instances"
Contact Information
AWS Support: https://aws.amazon.com/contact-us

MongoDB Support: https://support.mongodb.com

GitHub Support: https://support.github.com

