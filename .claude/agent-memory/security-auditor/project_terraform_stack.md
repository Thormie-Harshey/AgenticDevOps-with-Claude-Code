---
name: project_terraform_stack
description: Architecture and security posture of the DMI Cohort 2 static site Terraform stack
type: project
---

Static portfolio site deployed to AWS via Terraform. Stack: S3 (private, OAC-only) + CloudFront CDN + GitHub OIDC IAM role. Terraform state in S3 + DynamoDB (backend block commented out until bootstrap).

Files: main.tf, providers.tf, variables.tf, outputs.tf, backend.tf. terraform.tfstate present in repo (not gitignored). No GitHub Actions workflow files present as of 2026-03-12.

**Known security gaps (full audit confirmed 2026-03-16):**
- CRITICAL: terraform.tfstate committed to git (file present in repo root, tracked — no .gitignore exists). Even though the current state is empty (no deployed resources), the file is tracked and any future apply will commit live AWS secrets to git history.
- HIGH: No CloudFront WAF (aws_wafv2_web_acl) association — web_acl_id not configured in HCL
- HIGH: No security headers response policy on CloudFront — no aws_cloudfront_response_headers_policy resource; missing HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- HIGH: CloudFront using cloudfront_default_certificate = true with no minimum_protocol_version — defaults to TLSv1 on apply; must be explicitly set to TLSv1.2_2021
- HIGH: S3 bucket versioning not configured — no aws_s3_bucket_versioning resource; no rollback protection for content tampering
- HIGH: CloudFront compress field absent from HCL — defaults to false on apply; must be explicitly set to true
- MEDIUM: No S3 access logging (no aws_s3_bucket_logging resource) and no CloudFront access logging (no logging_config block)
- MEDIUM: Custom 404 → 200 rewrite — masks real error responses, hides security probing signals in logs
- MEDIUM: is_ipv6_enabled absent from HCL — defaults to false; should be set to true
- MEDIUM: Backend state bucket name ("tomiwadmi-terraform-state") and DynamoDB table ("tomiwadmi-terraform-locks") hardcoded in backend.tf comment
- MEDIUM: project_name variable default "tomiwadmi" hardcoded in variables.tf — leaks naming convention in source control
- MEDIUM: Backend block commented out — state stored locally; no remote locking or encryption enforced
- LOW: No provider default_tags block — tags must be set manually on every resource
- LOW: No .gitignore exists in repo — terraform.tfstate, .terraform/, terraform.tfvars are all unprotected
- LOW: outputs.tf exposes s3_bucket_arn without sensitive = true — ARN (containing account ID) will appear in CI logs
- LOW: cloudfront_domain_name and cloudfront_distribution_id outputs also not marked sensitive — distribution ID + domain in CI logs
- LOW: http_version absent from HCL — defaults to "http2"; should be set to "http2and3" for HTTP/3
- INFO: No OIDC IAM resources in terraform/ — GitHub Actions OIDC role may be provisioned out of band or not yet added

**Architecture positives:**
- OAC used correctly (not legacy OAI)
- All four public_access_block fields set to true
- viewer_protocol_policy = "redirect-to-https" is correct
- S3 bucket policy scoped to specific CloudFront ARN via SourceArn condition
- SSE-S3 (AES256) enabled via aws_s3_bucket_server_side_encryption_configuration

**Why:** Architecture is correct in fundamentals but missing defence-in-depth controls and has a critical state file exposure.
**How to apply:** Lead with the tfstate git exposure as the most urgent fix, then TLS version pinning, then WAF and security headers, then logging and versioning.
