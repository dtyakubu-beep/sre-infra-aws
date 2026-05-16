# -----------------------------------------------
# S3 Bucket — Terraform Remote State
# -----------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate"

  tags = {
    Name    = "${var.project_name}-tfstate"
    Purpose = "Terraform remote state storage"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------
# DynamoDB Table — State Locking
# -----------------------------------------------
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "${var.project_name}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  depends_on = [aws_s3_bucket.tfstate]

  tags = {
    Name    = "${var.project_name}-tfstate-lock"
    Purpose = "Terraform state locking"
  }
}

# -----------------------------------------------
# OIDC Provider — GitHub Actions Authentication
# -----------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  depends_on = [aws_dynamodb_table.tfstate_lock]

  tags = {
    Name    = "github-actions-oidc"
    Purpose = "GitHub Actions AWS authentication"
  }
}

# -----------------------------------------------
# IAM Role — GitHub Actions assumes this role
# -----------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/sre-*:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  depends_on = [aws_iam_openid_connect_provider.github]

  tags = {
    Name    = "${var.project_name}-github-actions-role"
    Purpose = "Role assumed by GitHub Actions pipeline"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}