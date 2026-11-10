#!/usr/bin/env bash
# Creates "the bucket nobody documented", the way the intern did it. Run once: ./setup.sh
set -u
cd "$(dirname "$0")"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials (aws sts get-caller-identity fails)." >&2; exit 1; }
B="clippy-exports-$ACCOUNT"
R=us-east-1
if aws s3api head-bucket --bucket "$B" 2>/dev/null; then echo "Bucket $B already exists. Nothing to do."; exit 0; fi
aws s3api create-bucket --bucket "$B" --region $R >/dev/null || exit 1
# The intern switched off the safety nets in the console:
aws s3api delete-public-access-block --bucket "$B" 2>/dev/null || true
aws s3api delete-bucket-encryption --bucket "$B" 2>/dev/null || true
TMP=$(mktemp)
for m in 01 02 03; do
  printf 'short_code,clicks\nabc%s,%s\n' "$m" "$((10#$m * 7))" > "$TMP"
  aws s3api put-object --bucket "$B" --key "exports/2026-$m.csv" --body "$TMP" >/dev/null
done
rm -f "$TMP"
echo "Created s3://$B in $R with 3 customer exports under exports/."
echo "It has no tags, no versioning and no rules. Do not touch it by hand: Terraform adopts it in the lab."
