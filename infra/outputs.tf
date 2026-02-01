output "bucket_name" {
  value = aws_s3_bucket.static_site.id
}

output "cloudfront_id" {
  value     = aws_cloudfront_distribution.static_dis.id
  sensitive = true
}

output "site_cd_role_arn" {
  value     = aws_iam_role.site_role.arn
  sensitive = true
}