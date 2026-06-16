---
name: patterns_common_findings
description: Recurring Terraform security anti-patterns and their canonical fixes observed across audits
type: reference
---

## S3

- Missing `aws_s3_bucket_server_side_encryption_configuration` → add SSE-S3 or SSE-KMS block
- Missing `aws_s3_bucket_logging` → add target_bucket and target_prefix
- Missing `aws_s3_bucket_versioning` → add versioning_configuration { status = "Enabled" }
- `restrict_public_buckets = false` or absent → set all four public_access_block fields to true
- `s3_bucket_arn` output not marked sensitive → add `sensitive = true` to outputs that contain account-identifying ARNs

## CloudFront

- `viewer_protocol_policy = "allow-all"` → change to "redirect-to-https"
- `origin_access_identity` (OAI) used instead of `origin_access_control_id` (OAC) → migrate to OAC
- No `aws_cloudfront_response_headers_policy` → add security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- `cloudfront_default_certificate = true` without explicit `minimum_protocol_version` → state defaults to TLSv1; always set TLSv1.2_2021 explicitly
- No `logging_config` block → add S3 logging bucket and prefix
- No WAF association → add `web_acl_id` pointing to aws_wafv2_web_acl (CLOUDFRONT scope)
- 404 rewritten to 200 silently → use 404 → 404 or document the SPA rewrite intent
- `compress` not set in HCL → state defaults to false; always set `compress = true` explicitly
- `is_ipv6_enabled` not set → defaults to false; set to true for full dual-stack coverage
- `http_version` not set → defaults to "http2"; set to "http2and3" to enable HTTP/3

## IAM

- Wildcard `"*"` in actions or resources → enumerate minimum required actions/ARNs
- OIDC sub condition uses `repo:org/*` → scope to specific repo and branch with `repo:org/repo:ref:refs/heads/main`
- No condition on AssumeRoleWithWebIdentity → require `StringEquals` on `token.actions.githubusercontent.com:sub`

## Terraform State

- terraform.tfstate committed to git → add to .gitignore immediately; rotate any exposed credentials; migrate to remote backend
- State file exposes AWS account IDs, resource ARNs, distribution IDs, and rendered IAM policy JSON in plaintext — treat as sensitive
- Backend block commented out → remind to migrate state before sharing repo
- Hardcoded bucket/table names in backend.tf → these leak account-specific naming conventions; move to tfvars or CI env vars

## General

- Hardcoded `default` values for project_name expose naming conventions — use tfvars instead
- No provider `default_tags` block → all resources should inherit mandatory tags automatically
- No .gitignore in terraform/ → terraform.tfstate, .terraform/, terraform.tfvars, *.tfvars should always be excluded
- Sensitive outputs (ARNs, domain names) not marked `sensitive = true` → they appear in CI logs in plaintext

## State File Cross-Checks

- Always diff HCL vs rendered state: `bucket_key_enabled = true` in HCL can show `false` in state (apply drift)
- `compress = false` in state overrides absent HCL compress field — always set `compress = true` explicitly
- `minimum_protocol_version` in viewer_certificate defaults to TLSv1 in state even when HCL omits it — always set explicitly to TLSv1.2_2021
- `response_headers_policy_id = ""` and `logging_config = []` in state confirm absence of security headers and access logging even when HCL is silent
- `web_acl_id = ""` in state confirms no WAF association
- State file `grant` block showing CanonicalUser FULL_CONTROL is the bucket owner grant — normal, not a misconfiguration
- `is_ipv6_enabled = false` in state when not set in HCL — always set explicitly
