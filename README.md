# sre-infra-aws
AWS Infra
# sre-infra-aws

Core AWS infrastructure for the SRE portfolio, provisioned entirely as code using Terraform and deployed via GitHub Actions CI/CD pipelines.

## Overview

This repository provisions and manages the foundational AWS infrastructure that all other SRE portfolio components run on. Everything is managed as code — no manual changes are ever made to the infrastructure directly.

## Architecture

```
GitHub (Push to main)
        │
        ▼
GitHub Actions (Terraform CI/CD)
        │
        ▼
AWS Infrastructure
├── VPC
│   ├── Public Subnets (x2, multi-AZ)
│   ├── Private Subnets (x2, multi-AZ)
│   ├── Internet Gateway
│   ├── NAT Gateway
│   └── Route Tables
└── EKS Cluster (Kubernetes 1.32)
    └── Node Group (t3.small x3)
```

## Key Design Decisions

**Remote State Management** — Terraform state is stored in S3 with DynamoDB locking, preventing concurrent pipeline runs from corrupting state.

**OIDC Authentication** — GitHub Actions authenticates to AWS using OpenID Connect, meaning no AWS access keys are ever stored in GitHub Secrets. This mirrors production security best practices.

**Modular Structure** — Infrastructure is split into reusable modules (`vpc`, `eks`) making it easy to extend and maintain.

**Bootstrap Separation** — A dedicated `bootstrap/` module handles one-time setup (S3 bucket, DynamoDB table, OIDC provider) separately from the main infrastructure, solving the chicken-and-egg problem of remote state.

**EKS Authentication** — Cluster uses `API_AND_CONFIG_MAP` authentication mode with access entries, enabling fine-grained IAM-based access control.

## Repository Structure

```
sre-infra-aws/
├── .github/
│   └── workflows/
│       ├── terraform.yaml   # Plan on PR, Apply on merge to main
│       └── destroy.yaml     # Manual destroy via workflow_dispatch
├── bootstrap/               # One-time setup — run locally
│   ├── main.tf              # S3, DynamoDB, OIDC, IAM role
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
├── modules/
│   ├── vpc/                 # VPC, subnets, IGW, NAT, route tables
│   └── eks/                 # EKS cluster, node group, IAM roles
├── main.tf                  # Wires modules together
├── variables.tf             # All configurable values
├── outputs.tf               # Cluster name, endpoint, VPC ID
├── providers.tf             # AWS provider configuration
└── backend.tf               # S3 remote state configuration
```

## CI/CD Pipeline

| Trigger | Action |
|---|---|
| Pull Request to `main` | `terraform plan` — shows what will change |
| Push to `main` | `terraform apply` — applies the changes |
| Manual (`workflow_dispatch`) | `terraform destroy` — tears down all infrastructure |

## Prerequisites

- AWS account with admin access
- GitHub repository secrets:
  - `AWS_ROLE_ARN` — IAM role ARN created by bootstrap

## Bootstrap (One-Time Setup)

```bash
cd bootstrap
terraform init
terraform apply -var="github_username=YOUR_GITHUB_USERNAME"
```

Note the outputs and add `AWS_ROLE_ARN` to GitHub Secrets.

## Usage

Push any change to `main` to trigger a deployment:

```bash
git commit --allow-empty -m "ci: trigger deployment"
git push origin main
```

To destroy all infrastructure:
- Go to **Actions** → **Terraform Destroy** → **Run workflow**

## Technologies

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| AWS EKS | Managed Kubernetes |
| AWS VPC | Network isolation |
| AWS IAM | Access control |
| GitHub Actions | CI/CD pipeline |
| OIDC | Keyless AWS authentication |
| S3 + DynamoDB | Remote state management |

## Related Repositories

| Repo | Description |
|---|---|
| [sre-monitoring-stack](https://github.com/dtyakubu-beep/sre-monitoring-stack) | Observability stack deployed into this cluster |
| [sre-sample-app](https://github.com/dtyakubu-beep/sre-sample-app) | Sample application deployed into this cluster |
| [sre-gitops-config](https://github.com/dtyakubu-beep/sre-gitops-config) | ArgoCD GitOps configuration |