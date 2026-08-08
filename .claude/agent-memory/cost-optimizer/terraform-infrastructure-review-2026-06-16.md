---
name: terraform-cost-review-2026-06-16
description: Cost optimization analysis of Terraform infrastructure (S3, CloudFront, DynamoDB, state backend)
metadata:
  type: project
---

# Cost Optimization Review — 2026-06-16

## Findings Summary
Reviewed 6 Terraform files (main.tf, providers.tf, variables.tf, backend.tf, github-oidc.tf, outputs.tf) for a static portfolio site using S3 + CloudFront.

## High-Impact Opportunities (Cost Reduction)

### 1. CloudFront Price Class — PriceClass_200 → PriceClass_100
- **Resource**: `aws_cloudfront_distribution.site` (line 88 in main.tf)
- **Current**: `price_class = "PriceClass_200"`
- **Recommended**: `price_class = "PriceClass_100"`
- **Why**: PriceClass_200 includes 200 edge locations; PriceClass_100 uses 100 cheapest edge locations. For a student portfolio project with low traffic, data transfer cost savings from 100 edge locations vs 200 will be negligible, but pricing tiers are lower in PriceClass_100.
- **Impact**: **MEDIUM savings** (~10-15% reduction in CloudFront costs, or $1-3/month if traffic is under 50GB/month)
- **Risk**: Minimal — no performance impact for portfolio use case. Users in remote regions may see slightly higher latency.

### 2. DynamoDB Billing Mode — Investigate Necessity vs use_lockfile
- **Resource**: `aws_dynamodb_table.tf_locks` (lines 169-183 in main.tf)
- **Current**: `billing_mode = "PAY_PER_REQUEST"` (on-demand pricing)
- **Recommended**: Consider removing this table entirely and use `use_lockfile = true` in backend (already set in backend.tf line 14)
- **Why**: The backend.tf already specifies `use_lockfile = true`, which means locking is handled by local .terraform.lock.hcl file, NOT DynamoDB. The DynamoDB table is redundant and incurs costs ($0.25/mil WCU + $1.25/mil RCU minimum per month on on-demand).
- **Impact**: **MEDIUM savings** (~$1-2/month in DynamoDB costs, minimal when multiplied across team)
- **Notes**: On-demand billing prevents "surprise spikes" but for a small team with infrequent terraform apply, provisioned capacity would be overkill anyway. Removing the table entirely is recommended if use_lockfile is confirmed working.

### 3. S3 State Bucket Versioning — Cleanup Strategy
- **Resource**: `aws_s3_bucket_versioning.tf_state` (lines 142-148 in main.tf)
- **Current**: `status = "Enabled"` — all versions preserved indefinitely
- **Recommended**: Add lifecycle rule to delete old versions after 30-90 days, or implement an S3 Intelligent-Tiering storage class
- **Why**: Terraform state files grow over time. Keeping all historical versions increases storage costs. Old versions beyond a rolling window (e.g., 90 days) are rarely needed for state recovery.
- **Impact**: **LOW savings initially** (scales with project lifetime). State bucket for a student project (~few MB) currently negligible, but establishes best practice (~$0.50-1/month if accumulated to 1GB+ of versions).
- **Consideration**: Balance cost vs rollback capability. Recommend 90-day retention minimum.

## Medium-Impact Findings (Monitor, not urgent)

### 4. CloudFront Cache Policy TTL
- **Resource**: `default_cache_behavior` (lines 97-105 in main.tf)
- **Current**: Using AWS Managed "CachingOptimized" policy (cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6")
- **Assessment**: This is optimal. CachingOptimized has appropriate TTLs (24 hours for static files, varies by type). No change needed.
- **Impact**: No action required — already cost-efficient.

### 5. S3 Site Bucket Configuration
- **Resource**: `aws_s3_bucket.site` (lines 8-15 in main.tf)
- **Current**: Standard storage class (no versioning, no lifecycle rules)
- **Assessment**: Correct for a static site. No improvement needed.
- **Impact**: No action required.

## No-Cost Resources (IAM, CloudFront OAC)
- IAM OIDC provider, IAM roles/policies, CloudFront OAC are **free** — no cost optimization available.

## Summary of Recommendations

| Priority | Resource | Savings | Effort |
|----------|----------|---------|--------|
| 1 | CloudFront: PriceClass_200 → PriceClass_100 | MEDIUM | Low |
| 2 | Remove DynamoDB table (use_lockfile active) | MEDIUM | Low |
| 3 | Add S3 state versioning lifecycle rule | LOW | Low |

**Estimated Total Monthly Savings**: $2-5/month (scales up as project grows and more deployments accumulate state versions).

## Next Steps
1. Change PriceClass_200 to PriceClass_100 in main.tf line 88
2. Verify backend uses use_lockfile, then remove DynamoDB table resource
3. (Optional) Add S3 lifecycle rule for state bucket to clean up old versions after 90 days
