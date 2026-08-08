# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static HTML/CSS portfolio website deployed to AWS using S3 + CloudFront, provisioned with Terraform, and automated via GitHub Actions.

## Architecture

### Application (Static Site)
- **index.html** — Single-page portfolio (About, Services, Courses, Books, Community, Contact)
- **style.css** — All styling (~1145 lines), mobile-first responsive (breakpoints: 900px, 768px, 600px)
- **privacy.html / terms.html** — Standalone pages with inline styles
- **images/** — Static assets (logo, profile, course thumbnails, hero background)
- Pure HTML5 + CSS3, no JavaScript, no build step

### Infrastructure (`terraform/`)
- AWS S3 bucket for static site hosting (private, OAC-based access)
- CloudFront distribution as CDN with S3 origin
- IAM role `tomiwadmi-github-actions-deploy` for keyless CI/CD auth, reading this AWS account's existing GitHub OIDC provider via a data source (the account already has one from another project — only one is allowed per account, and per-project IAM roles keep the two projects' deploy permissions independent)
- Terraform state lives in the `tomiwadmi-terraform-state` S3 bucket with DynamoDB locking (`backend.tf`)
- All resources tagged with `Project` and `Environment`

### CI/CD (`.github/workflows/`)
- The AWS infrastructure (IAM role, CloudFront distribution) was torn down after successful deployment, so the workflow no longer deploys
- GitHub Actions workflow now runs `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` on push to `main` and on pull requests — no AWS credentials involved
- With the infrastructure and OIDC role in place, it instead assumed the OIDC role, synced site files to S3, then invalidated the CloudFront cache

## MCP Servers (`.mcp.json`)

Two MCP servers are configured for Claude Code:
- **aws** (`awslabs.aws-api-mcp-server`) — Direct AWS API access for querying and managing resources
- **terraform** (`hashicorp/terraform-mcp-server`) — Terraform operations via Docker, workspace mounted at `/workspace`

AWS credentials and region are configured in `.claude/settings.local.json` (gitignored), not in `.mcp.json`. This keeps secrets out of version control and provides a single source of truth for all tools.

## Custom Agents (`.claude/agents/`)

This project has 4 specialized subagents. Use them by name when delegating tasks:
- **tf-writer** — generates Terraform code (has Write access + project memory)
- **security-auditor** — audits TF for security issues (Read-only, Sonnet)
- **cost-optimizer** — reviews infra cost (Read-only, Haiku)
- **drift-detector** — detects state drift (Bash, Haiku)

## Skills (`.claude/skills/`)

All infrastructure and deployment tasks are handled via skills. Do not write Terraform or CI/CD code manually — use the appropriate skill. Action skills have `disable-model-invocation: true` (manual only).

```
/scaffold-terraform [region] [name]  → Generate all Terraform files (uses tf-writer agent)
/tf-plan                             → Run terraform plan + risk analysis
/tf-apply                            → Run terraform apply + verify
/deploy                              → Sync S3 + invalidate CloudFront
/infra-status                        → Health dashboard of all resources
/infra-audit                         → Parallel security + cost + drift audit (forked context)
/setup-gh-actions [create|validate]  → Create or validate CI workflow
/commit                              → Auto-generate commit message (built-in)
/compact                             → Compress long conversation context (built-in)
```

## Commands

```bash
# Terraform
cd terraform && terraform init
cd terraform && terraform plan
cd terraform && terraform apply

# Local preview
open index.html

# Manual S3 sync (CI no longer does this — infra was torn down; run by hand if the bucket is repopulated)
aws s3 sync . s3://$BUCKET_NAME --exclude "terraform/*" --exclude ".git/*" --exclude ".github/*" --exclude "*.md" --exclude ".claude/*"
```

## Safety Layers
1. **UserPromptSubmit hook** — catches destructive intent ("delete all", "nuke", "wipe") before Claude starts
2. **PreToolUse hook** — blocks dangerous commands (terraform destroy, aws s3 rm) at execution time
3. **Permissions** — auto-allows safe reads, blocks IAM and rm -rf
4. **PostToolUse hook** — logs all terraform plan executions to `.claude/deploy.log`

## Conventions
- No JavaScript allowed in the project
- Mobile-first CSS approach
- All images stored in images/
- Terraform files use `terraform/` directory with standard layout (main.tf, variables.tf, outputs.tf)
- GitHub Actions uses OIDC — no stored AWS access keys
- All infrastructure changes go through Terraform — never modify AWS resources manually
- Site content no longer deploys automatically — the deploy role and CloudFront distribution were torn down after successful deployment; GitHub Actions now only validates Terraform on push to main

## DMI Ownership Customization (Required)

Before deployment, students must add ownership proof to the footer in `index.html`:

```html
<p><strong>Deployed by:</strong> DMI Cohort 2 | Ashaye Adetomiwa | Group 02 | Week 9 | 13-03-2026</p>
```

This customized footer must be visible in a browser screenshot submitted as deployment proof.
