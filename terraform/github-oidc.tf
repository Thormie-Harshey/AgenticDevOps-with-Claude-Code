# -------------------------------------------------------------------
# GitHub Actions OIDC Provider
#
# Only one OIDC provider per URL is allowed per AWS account. This
# account already has one (created for another project), so this
# reads it rather than trying to create a second one.
# -------------------------------------------------------------------
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# -------------------------------------------------------------------
# Trust policy — scoped to this repo + main branch only
# -------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Thormie-Harshey/AgenticDevOps-with-Claude-Code:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  # Project-scoped name — the AWS account already has an unrelated
  # "github-actions-deploy" role for another project; this must not
  # collide with it.
  name               = "${var.project_name}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# Deploy policy — minimal S3 sync + CloudFront invalidation only
# -------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "S3SyncSite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    sid       = "CloudFrontInvalidate"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.project_name}-github-actions-deploy-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

# -------------------------------------------------------------------
# Output for reference
# -------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "IAM role ARN to use in the GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
  sensitive   = true
}
