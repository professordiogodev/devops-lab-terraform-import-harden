# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `terraform/` with your `.tf` files (no state, no `.terraform/`)

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste `terraform plan` right after your import block, before you wrote any other setting. What did it show and why is it not empty?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the plan that hardened the bucket (public access block, versioning, encryption, lifecycle rule, TLS-only policy). Why did it say `update in-place` and not `replace`? What would `replace` have done to the files?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. Paste the `terraform plan` that detected drift after `./drift.sh` changed the bucket, and the apply that fixed it. Who changed what, and how would you find out in a real company?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Why does the state file contain secrets and bucket details, and why is it never committed? Where does `terraform.tfstate` live in your project right now and what is the risk of that?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. What is the difference between `terraform import` (or an `import` block), `terraform state rm` and `terraform destroy` for a resource that already exists? When would you use each?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q7. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
