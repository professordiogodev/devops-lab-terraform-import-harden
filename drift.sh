#!/usr/bin/env bash
# "A colleague fixed something in the console." Run it AFTER your bucket is under Terraform: ./drift.sh
set -u
ACCOUNT=$(aws sts get-caller-identity --query Account --output text) || exit 1
B="clippy-exports-$ACCOUNT"
aws s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Suspended
aws s3api delete-bucket-lifecycle --bucket "$B"
echo "Somebody changed $B behind Terraform's back. Run terraform plan to see what."
