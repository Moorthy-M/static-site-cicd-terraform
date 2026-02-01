// Create Bucket for Static Files
resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
  tags = merge(var.tags,
    {
      Name = "bucket-prod-static-site"
  })
}

// Block Public Access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Enable Versioning
resource "aws_s3_bucket_versioning" "version" {
  bucket = aws_s3_bucket.static_site.id

  versioning_configuration {
    status = "Enabled"
  }
}

// Default Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Create Origin Access Control
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "static-site-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

// Create Cloud Front Distribution
resource "aws_cloudfront_distribution" "static_dis" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id                = "s3-static-app-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-static-app-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = 403
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags,
    {
      Name = "cdn-prod-static-site"
  })
}

// Create Bucket Policy - Only Allow CDN
data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_dis.arn]
    }
  }
}

// Attach Policy to Bucket
resource "aws_s3_bucket_policy" "oac_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.policy.json
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

// Website CD Permission
data "aws_iam_policy_document" "site_cd_permission" {
  statement {
    sid    = "AllowBucketToUploadFiles"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = ["arn:aws:s3:::static-site-cicd-terraform", "arn:aws:s3:::static-site-cicd-terraform/*"]
  }

  statement {
    sid    = "AllowCloudFrontToInvalidateCache"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    condition {
      test     = "StringEquals"
      variable = "cloudfront:DistributionId"
      values   = [aws_cloudfront_distribution.static_dis.id]
    }

    resources = ["*"]
  }
}

// Create Website Role for CD
resource "aws_iam_role" "site_role" {
  name               = "terraform-cd-static-site-files-role"
  assume_role_policy = data.aws_iam_policy_document.cd_trust.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "role-static-site-files-cd"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

// Create Permission Policy to Upload Files and Cache Invalidation
resource "aws_iam_policy" "site_policy" {
  name   = "terraform-cd-static-site-files-permission-policy"
  policy = data.aws_iam_policy_document.site_cd_permission.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "policy-static-site-files-cd"
    Project     = "static-site-cicd-terraform"
    Environment = "production"
  }
}

// Attach Permission Policy to Role
resource "aws_iam_role_policy_attachment" "site_role_attach" {
  role       = aws_iam_role.site_role.name
  policy_arn = aws_iam_policy.site_policy.arn

  lifecycle {
    prevent_destroy = true
  }
}