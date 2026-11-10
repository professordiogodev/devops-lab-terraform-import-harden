#!/usr/bin/env bash
# Deletes the bucket and everything in it, all versions. Run with: ./teardown.sh
set -u
cd "$(dirname "$0")"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
B="clippy-exports-$ACCOUNT"
if aws s3api head-bucket --bucket "$B" 2>/dev/null; then
  echo "Emptying s3://$B (every version and delete marker)..."
  python3 - "$B" <<'PY'
import json, subprocess, sys
b = sys.argv[1]
while True:
    out = subprocess.check_output(["aws", "s3api", "list-object-versions", "--bucket", b, "--max-items", "500", "--output", "json"])
    v = json.loads(out or "{}")
    objs = [{"Key": x["Key"], "VersionId": x["VersionId"]} for x in (v.get("Versions") or []) + (v.get("DeleteMarkers") or [])]
    if not objs:
        break
    subprocess.check_call(["aws", "s3api", "delete-objects", "--bucket", b, "--delete", json.dumps({"Objects": objs, "Quiet": True})], stdout=subprocess.DEVNULL)
    print("  deleted", len(objs), "versions")
PY
fi
if [ -d terraform/.terraform ]; then
  echo "terraform destroy..."
  terraform -chdir=terraform destroy -auto-approve -input=false || true
fi
aws s3api head-bucket --bucket "$B" 2>/dev/null && aws s3api delete-bucket --bucket "$B" && echo "deleted the bucket directly"
rm -f terraform/terraform.tfstate terraform/terraform.tfstate.backup
echo "Now run ./verify-teardown.sh"
