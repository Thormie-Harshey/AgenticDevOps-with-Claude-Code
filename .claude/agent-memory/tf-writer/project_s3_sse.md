---
name: S3 SSE-S3 encryption pattern
description: AES256 SSE configuration added to the static site S3 bucket in main.tf, with bucket_key_enabled for forward-compatibility
type: project
---

`aws_s3_bucket_server_side_encryption_configuration.site` was added to `terraform/main.tf` immediately after `aws_s3_bucket.site` and before `aws_s3_bucket_public_access_block.site`.

Configuration choices:
- `sse_algorithm = "AES256"` — SSE-S3, no KMS cost, appropriate for a public static site
- `bucket_key_enabled = true` — reduces per-request KMS API overhead and makes a future migration to SSE-KMS a no-op config change

**Why:** Static site content is not sensitive, so SSE-KMS cost/complexity is unwarranted. AES256 satisfies encryption-at-rest requirements at zero extra cost.

**How to apply:** If adding more S3 resources to this project, follow the same resource-naming convention (`"site"`) and placement order: bucket -> SSE -> public_access_block -> policy.
