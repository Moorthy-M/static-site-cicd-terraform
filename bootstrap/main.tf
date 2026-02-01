locals {
  tf_state_bucket_arn = "arn:aws:s3:::s3-moorthy-terraform-state"
}

// Infra CI Trust Policy
data "aws_iam_policy_document" "ci_trust" {
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
      values = [
        "repo:Moorthy-M/static-site-cicd-terraform:pull_request",
        "repo:Moorthy-M/static-site-cicd-terraform:ref:refs/heads/*"
      ]
    }
  }
}

// Infra CD Trust Policy
data "aws_iam_policy_document" "cd_trust" {
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

// Infra CI Permisssions
data "aws_iam_policy_document" "ci_permission" {
  statement {
    sid    = "TerraformStateRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [local.tf_state_bucket_arn, "${local.tf_state_bucket_arn}/*"]
  }

  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::static-site-*"
    ]
  }

  statement {
    sid    = "CloudFrontReadOnly"
    effect = "Allow"

    actions = [
      "cloudfront:Get*",
      "cloudfront:ListDistributions",
      "cloudfront:ListOriginAccessControls",
      "cloudfront:ListTagsForResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReadTerraformRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]

    resources = ["arn:aws:iam::*:role/terraform-*"]
  }

  statement {
    sid    = "ReadTerraformPolicies"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion"
    ]

    resources = ["arn:aws:iam::*:policy/terraform-*"]
  }
}

// Infra CD Permissions
data "aws_iam_policy_document" "cd_permission" {
  statement {
    sid    = "TerraformState"
    effect = "Allow"

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
    actions   = ["s3:CreateBucket", "s3:DeleteBucket"]
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
      "s3:PutBucketTagging",
      "s3:PutEncryptionConfiguration",
      "s3:Get*",
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
      "cloudfront:Get*",
      "cloudfront:List*",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:ListTagsForResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CreateRole"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole"
    ]

    resources = ["arn:aws:iam::*:role/terraform-*"]
  }

  statement {
    sid    = "CreatePolicy"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListPolicyVersions"
    ]

    resources = ["arn:aws:iam::*:policy/terraform-*"]
  }

  statement {
    sid    = "AttachAndDetachPolicies"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]

    resources = ["arn:aws:iam::*:role/terraform-*"]
  }
}

// Create Role for CI
resource "aws_iam_role" "ci_role" {
  name               = "terraform-ci-static-site-role"
  assume_role_policy = data.aws_iam_policy_document.ci_trust.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "role-static-site-ci"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

// Create Permission Policy for CI
resource "aws_iam_policy" "ci_policy" {
  name   = "terraform-ci-static-site-permission-policy"
  policy = data.aws_iam_policy_document.ci_permission.json

  tags = {
    Name        = "policy-static-site-ci"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

//Attach Permission Policy to Role
resource "aws_iam_role_policy_attachment" "cd_role_attach" {
  role       = aws_iam_role.ci_role.name
  policy_arn = aws_iam_policy.ci_policy.arn

  lifecycle {
    prevent_destroy = true
  }
}

// Create Role for CD
resource "aws_iam_role" "cd_role" {
  name               = "terraform-cd-static-site-role"
  assume_role_policy = data.aws_iam_policy_document.cd_trust.json

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
  policy = data.aws_iam_policy_document.cd_permission.json

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
