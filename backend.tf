terraform {
  backend "s3" {
    bucket         = "sre-portfolio-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "sre-portfolio-tfstate-lock"
  }
}