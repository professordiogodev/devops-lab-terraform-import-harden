#!/usr/bin/env bash
rc=0
ls terraform/*.tf >/dev/null 2>&1 && echo "- ✅ terraform/ has .tf files" || { echo "- ❌ terraform/ has no .tf files"; rc=1; }
grep -q 'aws_s3_bucket_public_access_block' terraform/*.tf && grep -q 'aws_s3_bucket_versioning' terraform/*.tf && grep -q 'aws_s3_bucket_lifecycle_configuration' terraform/*.tf && echo "- ✅ the hardening resources are in the code" || { echo "- ❌ the hardening resources (public access block, versioning, lifecycle...) are missing"; rc=1; }
if git ls-files | grep -qE '\.tfstate|\.terraform/|\.tfvars$'; then echo "- ❌ state, .terraform/ or tfvars is committed"; rc=1; else echo "- ✅ no state or .terraform/ committed"; fi
grep -rEq 'AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude=tfcheck.py && { echo "- ❌ an AWS access key is committed"; rc=1; } || echo "- ✅ no AWS access key committed"
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
