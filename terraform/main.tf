terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      lab     = "terraform-import-harden"
      Project = "clippy"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # The intern's bucket. setup.sh created it with this name.
  bucket = "clippy-exports-${data.aws_caller_identity.current.account_id}"
}

# TODO 1 (Part 1): adopt the existing bucket with an `import` block and a matching
#                  resource "aws_s3_bucket" "exports". Run terraform plan: it must say
#                  "1 to import" and nothing to destroy.
#
# TODO 2 (Part 2): make it safe, in code. One resource per setting (AWS provider v6):
#   - aws_s3_bucket_public_access_block   all four options true
#   - aws_s3_bucket_versioning            Enabled
#   - aws_s3_bucket_server_side_encryption_configuration   AES256
#   - aws_s3_bucket_lifecycle_configuration   expire objects under "exports/" after 30 days,
#                                             and also expire NONCURRENT versions after 30 days
#   - aws_s3_bucket_policy                deny every request that is not HTTPS (aws:SecureTransport = false)
#
# TODO 3 (Part 4): an output "bucket_name" with the name.
