# Static Website - Terraform + CICD + S3 + CloudFront

## Overview
This project demonstrates a **production-style static website deployment** on AWS using **Terraform**, **Amazon S3**, **CloudFront**, and **GitHub Actions**.  
The primary focus is on **Infrastructure as Code, CI/CD automation, and secure IAM design** rather than frontend development.

---

## Problem Statement
Hosting a static website in production involves more than uploading files:
- Infrastructure must be reproducible
- Storage must be private and secure
- Deployments must be automated
- CDN caching must be handled correctly

This project addresses these challenges using AWS-native services and DevOps best practices.

---

## Architecture
- **Amazon S3** – Private bucket for static website assets  
- **Amazon CloudFront** – CDN with Origin Access Control (OAC)  
- **Terraform** – Infrastructure as Code  
- **GitHub Actions** – CI/CD using OIDC-based authentication  

> HTTPS via ACM is intentionally excluded because no custom domain is configured.

---

## Infrastructure Design

### Bootstrap Layer
- IAM roles and policies
- GitHub Actions OIDC trust relationship
- Least-privilege permissions for CI/CD workflows

### Application Layer
- Private S3 bucket (no public access, no ACLs)
- CloudFront distribution with OAC
- IAM role for site deployment
- IAM permissions for CloudFront cache invalidation

All infrastructure is fully provisioned and managed using Terraform.

---

## CI/CD Workflow

### Continuous Integration (CI)
Triggered on **Pull Requests**:
- Dependency installation
- Build validation

> **Note on Linting & Tests**  
> This project is based on a **forked frontend repository**. Existing lint and test issues originate from the upstream project and are considered **application-level concerns**.  
> Since the goal of this project is to demonstrate **DevOps and infrastructure practices**, linting and tests are intentionally skipped in CI and assumed to be owned by the application developer.

### Continuous Deployment (CD)
Triggered on **merge to `main`**:
- Static site build
- Upload artifacts to S3
- CloudFront cache invalidation to serve updated content

---

## Security
- S3 bucket is fully private
- CloudFront is the only allowed origin consumer
- No public bucket policies or ACLs
- No long-lived AWS credentials
- GitHub Actions uses OIDC-based role assumption
- IAM policies follow least-privilege principles

---

## Key Learnings
- Implementing CI/CD with OIDC instead of access keys
- Understanding CloudFront IAM limitations
- Separating bootstrap and application infrastructure
- Handling real-world CI failures (IAM, CLI, pipeline design)
- Designing secure and automated static website deployments

---

## Current Status
- Infrastructure provisioned with Terraform
- CI pipeline implemented
- CD pipeline implemented
- Secure IAM roles and policies configured
- CloudFront cache invalidation automated

---

## Why This Project
This project reflects **real-world DevOps responsibilities**, focusing on:
- Infrastructure automation
- Secure identity and access management
- CI/CD pipeline design
- Production-aware tradeoffs

Frontend code quality and testing are deliberately treated as **separate ownership**, aligning with how responsibilities are divided in real engineering teams.
