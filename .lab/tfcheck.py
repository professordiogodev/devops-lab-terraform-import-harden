#!/usr/bin/env python3
import json, os, re, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)
ACCOUNT = sys.argv[1]
B = "clippy-exports-" + ACCOUNT
passed = failed = 0


def check(desc, ok, hint=""):
    global passed, failed
    if ok:
        passed += 1; print("PASS  " + desc)
    else:
        failed += 1; print("FAIL  " + desc + (("   -> " + hint) if hint else ""))


def aws(*a):
    try:
        return json.loads(subprocess.check_output(("aws",) + a + ("--output", "json"), stderr=subprocess.DEVNULL, timeout=60) or "null")
    except Exception:
        return None


def sh(c):
    r = subprocess.run(c, shell=True, capture_output=True, text=True)
    return r.returncode, r.stdout


def tracked():
    return sh("git ls-files")[1].split("\n")


print("== Your code ==")
tf = sh("cat terraform/*.tf")[1]
check("terraform fmt -check is clean", sh("terraform -chdir=terraform fmt -check")[0] == 0, "terraform -chdir=terraform fmt")
check("no state file, .terraform/ or tfvars committed", not [f for f in tracked() if re.search(r"\.tfstate|(^|/)\.terraform/|\.tfvars$", f)])
check("no AWS keys in the repository", sh("git grep -lE 'AKIA[0-9A-Z]{16}' -- . ':!.lab' ':!verify.sh'")[1].strip() == "")

print("== The bucket in AWS ==")
check("the bucket %s still exists" % B, aws("s3api", "head-bucket", "--bucket", B) is not None or sh("aws s3api head-bucket --bucket %s" % B)[0] == 0)
for m in ("01", "02", "03"):
    k = "exports/2026-%s.csv" % m
    rc, out = sh("aws s3 cp s3://%s/%s -" % (B, k))
    check("customer file %s is untouched" % k, rc == 0 and out.startswith("short_code,clicks\nabc%s," % m), "never destroy and recreate this bucket")
pab = aws("s3api", "get-public-access-block", "--bucket", B)
c = (pab or {}).get("PublicAccessBlockConfiguration", {})
check("all four public access block options are on", len(c) == 4 and all(c.values()))
ver = aws("s3api", "get-bucket-versioning", "--bucket", B) or {}
check("versioning is Enabled", ver.get("Status") == "Enabled")
enc = aws("s3api", "get-bucket-encryption", "--bucket", B) or {}
rules = enc.get("ServerSideEncryptionConfiguration", {}).get("Rules", [])
check("default encryption is on (AES256 or aws:kms)", bool(rules) and rules[0]["ApplyServerSideEncryptionByDefault"]["SSEAlgorithm"] in ("AES256", "aws:kms"))
lc = (aws("s3api", "get-bucket-lifecycle-configuration", "--bucket", B) or {}).get("Rules", [])
cur = any(r.get("Status") == "Enabled" and r.get("Expiration", {}).get("Days") == 30 and "exports/" in json.dumps(r.get("Filter", {})) for r in lc)
nc = any(r.get("Status") == "Enabled" and r.get("NoncurrentVersionExpiration", {}).get("NoncurrentDays") == 30 for r in lc)
check("lifecycle: objects under exports/ expire after 30 days", cur)
check("lifecycle: noncurrent versions expire after 30 days", nc)
pol = aws("s3api", "get-bucket-policy", "--bucket", B)
doc = {}
try:
    doc = json.loads(pol["Policy"])
except Exception:
    pass
check("bucket policy denies requests that are not HTTPS (aws:SecureTransport = false)",
      any(s.get("Effect") == "Deny" and "SecureTransport" in json.dumps(s.get("Condition", {})) and "false" in json.dumps(s.get("Condition", {})).lower() for s in doc.get("Statement", [])))
tags = {t["Key"]: t["Value"] for t in (aws("s3api", "get-bucket-tagging", "--bucket", B) or {}).get("TagSet", [])}
check("the bucket is tagged Project=clippy and lab=terraform-import-harden", tags.get("Project") == "clippy" and tags.get("lab") == "terraform-import-harden", "default_tags in the provider")

print("== Terraform state ==")
rc, st = sh("terraform -chdir=terraform state list")
check("the state tracks the bucket and its settings (6 or more resources)", rc == 0 and len([l for l in st.split("\n") if l.startswith("aws_")]) >= 6, "terraform init, import, apply")
rc, out = sh("terraform -chdir=terraform plan -detailed-exitcode -input=false -no-color")
check("terraform plan finds nothing to change (the code is the truth, no drift)", rc == 0, "plan exit code %d: apply, or fix the code" % rc)
check("terraform output bucket_name prints the name", sh("terraform -chdir=terraform output -raw bucket_name")[1].strip() == B)

print()
print(("ALL CHECKS PASSED (%d/%d)" % (passed, passed)) if failed == 0 else ("%d check(s) failed, %d passed" % (failed, passed)))
sys.exit(1 if failed else 0)
