# Remote State Backend (S3 + DynamoDB locking)
#
# INSTRUCTIONS:
# 1. Run `terraform init` and `terraform apply` WITHOUT this backend block first
#    to create the S3 bucket and DynamoDB table for state storage.
# 2. Once those resources exist, uncomment the backend block below.
# 3. Run `terraform init -migrate-state` to move local state to S3.
#
# terraform {
#   backend "s3" {
#     bucket         = "tomiwadmi-terraform-state"
#     key            = "static-site/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "tomiwadmi-terraform-locks"
#     encrypt        = true
#   }
# }
