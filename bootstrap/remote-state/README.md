# Remote State Bootstrap (Task 2)

Creates the control-plane foundation used by the root stack:

- S3 state bucket (versioned, public access blocked)
- SSE-KMS with a dedicated CMK (rotation enabled)
- DynamoDB lock table (`LockID`, PITR enabled)

`prevent_destroy` is set on bucket, key, and table — losing them is worse than a failed destroy during experiments.

## Apply

```bash
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
terraform init
terraform apply -var="state_bucket_name=arrise-devops-tfstate-${ACCOUNT_ID}"
```

Then copy values into `backend.hcl` at the repo root (see `backend.hcl.example`) and run:

```bash
terraform -chdir=../.. init -backend-config=backend.hcl
```

## Why a separate stack?

The backend cannot safely manage its own bucket inside the same state it stores. Bootstrap once; consume many times from workload states.
