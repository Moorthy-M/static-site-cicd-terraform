output "bucket_name" {
  value = aws_s3_bucket.static_site.id
}

output "cloudfront_arn" {
  value     = aws_cloudfront_distribution.static_dis.arn
  sensitive = true
}