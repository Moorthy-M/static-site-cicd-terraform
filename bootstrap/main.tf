locals {
  tf_state_bucket_arn = "arn:aws:s3:::s3-moorthy-terraform-state"
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid    = "TrustPolicyForAssumeRole"
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Moorthy-M/static-site-cicd-terraform:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "permission" {
  statement {
    sid = "TerraformState"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [local.tf_state_bucket_arn, "${local.tf_state_bucket_arn}/*"]
  }

  statement {
    sid       = "CreateStaticSiteBuckets"
    effect    = "Allow"
    actions   = ["s3:CreateBucket"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "s3:bucketName"
      values   = ["static-site-*"]
    }
  }

  statement {
    sid    = "ManageStaticSiteBuckets"
    effect = "Allow"

    actions = [
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucket*",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::static-site-*"
    ]
  }

  statement {
    sid    = "ManageStaticSiteObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::static-site-*/*"
    ]
  }

  statement {
    sid    = "CloudFrontDeploy"
    effect = "Allow"

    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl"
    ]

    resources = ["*"]
  }
}

// Create Role for CD
resource "aws_iam_role" "cd_role" {
  name               = "terraform-cd-static-site-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "role-static-site-cd"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

// Create Permission Policy to Create S3 and CloudFront
resource "aws_iam_policy" "policy" {
  name   = "terraform-cd-static-site-permission-policy"
  policy = data.aws_iam_policy_document.permission.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "policy-static-site-cd"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

// Attach Permission Policy to Role
resource "aws_iam_role_policy_attachment" "cd_role" {
  role       = aws_iam_role.cd_role.name
  policy_arn = aws_iam_policy.policy.arn

  lifecycle {
    prevent_destroy = true
  }
}