# Partial backend configuration.
# Reviewers supply bucket/key/table via backend.hcl (see backend.hcl.example).
# Skip remote state entirely with: terraform init -backend=false
terraform {
  backend "s3" {}
}
