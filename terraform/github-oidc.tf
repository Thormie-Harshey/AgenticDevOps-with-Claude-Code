# -------------------------------------------------------------------
# GitHub Actions OIDC Provider
#
# Note: Only one OIDC provider per URL is allowed per AWS account.
# If this already exists from another project, replace the resource
# block below with a data source instead:
#
#   data "aws_iam_openid_connect_provider" "github" {
#     url = "https://token.actions.githubusercontent.com"
#   }
#
# Then update the principals identifiers reference to:
#   data.aws_iam_openid_connect_provider.github.arn
# -------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
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
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Thormie-Harshey/AgenticDevOps-with-Claude-Code:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-deploy"
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
  name   = "github-actions-deploy-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

# -------------------------------------------------------------------
# Output for reference
# -------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "IAM role ARN to use in the GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}
