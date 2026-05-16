output "tfstate_bucket_name" {
  description = "S3 bucket name for Terraform state — add to backend.tf"
  value       = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking — add to backend.tf"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "github_actions_role_arn" {
  description = "IAM Role ARN — add this to GitHub Secrets as AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}