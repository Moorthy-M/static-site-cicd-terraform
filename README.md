# Static Website – Terraform + S3 + CloudFront

## Overview
Production-grade static website delivery using AWS S3, CloudFront, Terraform, and CI/CD.

## Architecture
- S3 (private origin)
- CloudFront (OAC enabled)
- HTTPS via ACM
- Terraform for IaC
- GitHub Actions for CI/CD

## Environments
- dev
- prod

## CI/CD Flow
- PR → validate
- Merge → deploy

## Security
- Private S3 bucket
- Least-privilege IAM
- No public ACLs

## Status
🚧 In Progress

