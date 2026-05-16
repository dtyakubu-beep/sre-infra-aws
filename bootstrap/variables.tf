variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sre-portfolio"
}

variable "github_username" {
  description = "Your GitHub username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name"
  type        = string
  default     = "sre-infra-aws"
}