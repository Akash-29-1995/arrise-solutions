# Reviewer guide — start here

This repository is meant to be **read as an architecture**, then **run without guessing**.

| If you want… | Do this | Time | AWS cost |
|--------------|---------|------|----------|
| Prove the code is valid | `make reviewer-validate` | ~1–2 min | **$0** |
| Run Tasks 3–4 in a sandbox account | `make sandbox-up` | ~3–5 min | **pennies** (IAM + 1 S3 bucket) |
| Also exercise Task 1 EC2 | `SANDBOX_WITH_EC2=1 make sandbox-up` | ~5–10 min | **low** (cheap inventory) |
| Understand decisions | `NOTES.md` + `docs/adr/` | — | — |

---

## Path A — Offline (no AWS)

```bash
git clone <this-repo> && cd arrise
make reviewer-validate
```

What it does:

1. Preflight (Terraform present)
2. Offline assignment contract checks (`scripts/verify-requirements.sh`)
3. `terraform fmt -check`
4. `terraform validate` for root + state bootstrap (backend disabled)

You do **not** need AWS credentials for Path A.

---

## Path B — Sandbox in your AWS account (recommended live demo)

Uses **your** credentials, **one** account (Account A = Account B = caller), **local Terraform state**, and a **unique `name_prefix`** so shared sandboxes do not collide on `roleA` / `engine` names.

### Prerequisites

- Terraform `>= 1.5`
- AWS CLI v2 with credentials (`aws sts get-caller-identity` works)
- IAM permissions to create users/groups/roles and one S3 bucket

### Up

```bash
make sandbox-up
# non-interactive:
# SANDBOX_AUTO_APPROVE=1 make sandbox-up
```

### What you should see

```bash
terraform output deployment_mode          # single-account-reviewer
terraform output name_prefix              # arrise-sbx-xxxxxx-
terraform output account_a_role_b_arn
terraform output account_b_role_c_arn
terraform output role_c_bucket_name
terraform output ci_policy_json
```

Smoke test (with your admin creds):

```bash
aws sts assume-role \
  --role-arn "$(terraform output -raw account_a_role_b_arn)" \
  --role-session-name reviewer-roleb
```

### Down

```bash
make sandbox-down
# SANDBOX_AUTO_APPROVE=1 make sandbox-down
```

---

## Path C — Sandbox + EC2 (Task 1 live)

```bash
SANDBOX_WITH_EC2=1 make sandbox-up
```

- Uses `inventory/dev-instances-cheap.yaml`
- Auto-generates an ephemeral SSH key (`generate_ssh_key=true`)
- Still single-account + local state + unique prefix

```bash
terraform output instance_ids_by_name
terraform output private_ips_by_name
terraform output protected_instance_names   # ledger-a
```

> `ledger-a` has `prevent_destroy`. If destroy complains, set `protected: false` in the cheap inventory, apply, then `make sandbox-down`.

---

## Path D — Full assignment shape (remote state + optional dual account)

Use when you want Task 2 exactly as production would:

```bash
# 1) bootstrap state
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform -chdir=bootstrap/remote-state init
terraform -chdir=bootstrap/remote-state apply \
  -var="state_bucket_name=arrise-devops-tfstate-${ACCOUNT_ID}"

# 2) wire backend
cp backend.hcl.example backend.hcl   # set bucket name
cp terraform.tfvars.example terraform.tfvars
# set ssh_public_key; leave account IDs empty for single-account

terraform init -backend-config=backend.hcl
terraform apply -var='enable_ec2=false'
```

Dual-account: set `account_a_id`, `account_b_id`, and deploy role ARNs in `terraform.tfvars` (see example file).

---

## How to grade quickly

| Task | Look at | Prove |
|------|---------|-------|
| 1 | `modules/ec2_fleet`, `inventory/*` | one map, diversity validations, `ledger-a` protected, outputs |
| 2 | `bootstrap/remote-state`, `backend.tf`, `NOTES.md` §Task 2 | S3 + DynamoDB lock story |
| 3 | `modules/iam_account_*`, ADR 0002 | exact `roleB` trust, groups/roles |
| 4 | `policies/ci-policy.json` + module policy | custom least privilege, not PowerUser |
| 5 | `examples/task5-fixed-snippet.tf` + `NOTES.md` | user→role ARN + scoped S3 |

Architecture narrative (why, not only what): **`NOTES.md`**, **`docs/architecture.md`**, **`docs/adr/`**.

---

## Design stance (why this stands out)

1. **Control plane ≠ data plane** — state bootstrap is a separate stack (ADR 0001).
2. **Trust is a broker, not an account** — `roleB` only (ADR 0002).
3. **Snowflakes vs cattle** — inventory EC2 for the brief; ASG module for scale (ADR 0003).
4. **Runnable** — offline contracts + one-command sandbox with collision-safe prefixes.
5. **Honest production deltas** — no access keys in state; Identity Center / OIDC called out in NOTES.
