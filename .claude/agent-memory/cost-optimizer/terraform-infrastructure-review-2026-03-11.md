---
name: Terraform Static Site Cost Review
description: Cost optimization analysis of S3 + CloudFront static site Terraform configuration
type: project
---

## Infrastructure Summary
- **Static Site**: HTML/CSS portfolio deployed via S3 + CloudFront
- **Region**: eu-north-1
- **Resources Deployed**: S3 bucket, CloudFront distribution (PriceClass_200), OAC, bucket policy
- **State Backend**: S3 + DynamoDB (commented out, not yet active)

## Cost Patterns Identified

### CloudFront
- Using PriceClass_200 (moderate price class)
- AWS Managed CachingOptimized policy applied
- 404 error caching TTL set to 10 seconds (low value)
- No custom cache behaviors defined
- Serves from eu-north-1 (relatively low cost region)

### S3
- Bucket public access blocked (good security practice)
- No versioning, lifecycle policies, or storage classes explicitly configured
- Likely using S3 Standard storage (default)
- OAC-based access control for CloudFront

### Terraform State
- Remote state backend commented out (currently using local state)
- When enabled: S3 backend + DynamoDB locking in eu-north-1

## High-Impact Cost Optimization Opportunities
1. **CloudFront PriceClass_100** — Could save 30-50% on data transfer if suitable for target audience
2. **S3 Storage Lifecycle** — No lifecycle rules for old objects (potential savings if content archival needed)
3. **404 Error Caching** — 10 second TTL is very low; could increase to reduce origin requests

## Low-Risk Configuration
- Region choice (eu-north-1) is cost-effective
- Caching policy (CachingOptimized) is appropriate for static content
- No unnecessary resources or redundancy
