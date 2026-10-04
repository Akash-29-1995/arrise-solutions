# NOTES — Architecture & Assignment Answers

> **Reviewers:** run instructions live in [`REVIEWER.md`](REVIEWER.md).  
> Decision records: [`docs/adr/`](docs/adr/).

## 0. Executive summary

This submission treats the brief as an **infrastructure architecture exercise**, not a Terraform syntax quiz.

- Compute is **inventory-driven** and separable from IAM.
- State is **remote, encrypted, locked**, and bootstrapped as its own stack (sandbox can use local state on purpose).
- Identity uses **account boundaries**, **exact-principal trust**, and **custom least privilege**.
- Sandbox runs use a unique `name_prefix` so shared reviewer accounts do not collide on IAM names.
- Production deviations from the assignment (no long-lived access keys, Identity Center for humans, ASG for homogeneous fleets) are called out explicitly.

| Intent | Command |
|--------|---------|
| Offline proof | `make reviewer-validate` |
| Live sandbox (IAM) | `make sandbox-up` |
| Teardown | `make sandbox-down` |

---

## 1. Assignment answers (direct)

### Task 1 — Which instance is protected, and why?

**`ledger-a`.**

It is marked `protected = true`, which places it in the `aws_instance.protected` resource with:

- `lifecycle { prevent_destroy = true }`
- `disable_api_termination = true`

I chose it because it represents a **stateful / high-criticality** node. Losing a stateless `web-*` or `worker-*` instance is an availability event; losing a ledger-like node is a **data and consistency** event. Protection should follow business criticality, not alphabetical order.

Terraform cannot set `prevent_destroy` conditionally inside one `for_each` resource, so the module splits standard vs protected instances while still consuming **one input map**.

### Task 2 — Local state race vs remote lock

**Today (local state):** two engineers can `apply` concurrently from different laptops, both reading the same pre-apply state, both writing resources, and both writing state files. Last writer wins; the other engineer’s state view is silently wrong. Drift and duplicate/conflicting resources follow.

**With this backend:** state lives in S3; DynamoDB stores a `LockID` lock for the duration of the operation. The second apply fails fast with a lock error instead of corrupting shared understanding of reality. Versioning + KMS on the state bucket add recovery and confidentiality.

### Task 3 — Would you give `engine` and `ci` IAM users with access keys in production?

**No.**

| Actor | Production pattern |
|-------|--------------------|
| Human (`engine`) | IAM Identity Center (SSO), MFA, short-lived role sessions |
| CI (`ci`) | OIDC federation (GitHub Actions / GitLab / etc.) → assume role; no static keys |

Long-lived access keys are hard to rotate, easy to leak into logs/artifacts, and tend to accumulate privilege. This repo **does not** create `aws_iam_access_key` resources so secrets never land in state. group1 users are created under `/programmatic/` with **no login profile**, a group policy that only allows assuming `roleB` (+ `GetCallerIdentity`), and an explicit deny on self-service login-profile / access-key creation.

### Task 3 — Why trust `roleB` ARN instead of Account A root?

Trusting `arn:aws:iam::ACCOUNT_A:root` delegates the decision to **anyone in Account A who is allowed to assume roleC** (identity policy in A + trust in B). Any future over-privileged principal in A becomes a cross-account path into B.

Trusting `arn:aws:iam::ACCOUNT_A:role/roleB` makes the trust relationship a **single broker role**. Expanding who can reach the bucket means changing roleB’s trust/identity policies deliberately — not accidentally inheriting every admin in Account A.

### Task 4 — What did the CI policy deliberately leave out?

Left out on purpose:

- Managed policies (`AdministratorAccess`, `PowerUserAccess`)
- `iam:*` except tightly conditioned `PassRole` to two task roles
- `s3:Put*`, `s3:Delete*`, and any other bucket
- ECR push to `*` repositories
- ECS mutations outside the named cluster/service
- Network/security/database provisioning APIs

Wildcards remain only where AWS requires them (`ecr:GetAuthorizationToken`, `ecs:RegisterTaskDefinition`, task-definition reads). Those statements are isolated so the wildcard surface is auditable.

### Task 5 — Why the snippet failed (two bugs)

1. **Trust principal:** `arn:aws:iam::000000000000:user/roleB` refers to an IAM **user** named `roleB`. The assignment’s `roleB` is a **role**. Correct principal: `arn:aws:iam::000000000000:role/roleB`.
2. **Permissions:** `s3:*` on `Resource = "*"` grants every bucket. The requirement is full access to **one named bucket**, so resources must be `arn:aws:s3:::bucket` and `arn:aws:s3:::bucket/*`.

Fixed reference: `examples/task5-fixed-snippet.tf`. Live implementation: `modules/iam_account_b`.

---

## 2. Architectural approach

### 2.1 Control plane vs data plane

```text
Bootstrap stack     → state bucket, lock table, KMS (control plane foundation)
Root stack          → EC2 fleet + IAM (workloads / identity)
Optional ASG module → production compute pattern (not wired; reference design)
```

Separating backend bootstrap from workload state avoids the chicken-and-egg of storing state in a bucket defined in the same state file.

### 2.2 Account strategy

| Mode | When | How |
|------|------|-----|
| Single-account reviewer | Hire-loop validation | `account_a_id` / `account_b_id` default to caller; no assume_role |
| Dual-account | Real isolation | Distinct IDs + deploy role ARNs on provider aliases |

Same-account mode still exercises AssumeRole chains (`user → roleB → roleC`). Dual-account mode is the intended production shape.

### 2.3 Scaling 5 → 500

| Fleet shape | Pattern |
|-------------|---------|
| Heterogeneous snowflakes (this assignment) | Inventory YAML/JSON → `for_each` module; split state by blast radius |
| Homogeneous app servers | Launch template + ASG + multi-AZ + ELB health + instance refresh (`modules/asg_service`) |

Managing 500 unique `aws_instance` objects in one state is an operational anti-pattern: plan times, lock contention, and blast radius all degrade. Prefer **platform primitives** (ASG/ECS/EKS) once instances are cattle.

### 2.4 Multi-tenancy

Preferred for regulated / high-trust workloads: **account-per-tenant** (or account-per-env) under AWS Organizations with SCPs. Shared-account tenancy (VPC-per-tenant or IAM/tag isolation) is cheaper but weaker. State keys should mirror the tenancy model:

```text
s3://tfstate/
  account-a/dev/ap-south-1/iam.tfstate
  account-a/dev/ap-south-1/ec2-web.tfstate
  tenant-a/prod/ap-south-1/workload.tfstate
```

### 2.5 Security posture encoded in code

- IMDSv2 required on EC2
- Root volumes encrypted
- roleC trust = exact role ARN
- roleA has explicit Deny on `iam:*` (Allow via NotAction alone is weaker under policy evaluation edge cases)
- CI `PassRole` conditioned on `ecs-tasks.amazonaws.com`
- State: SSE-KMS, versioning, public access block, DynamoDB PITR
- No access keys in Terraform
- Console login profiles off by default (passwords in state are an anti-pattern)

Production additions I would mandate next: CloudTrail org trail, GuardDuty, Security Hub, SCPs, permission boundaries for delegated admins, and CI OIDC.

---

## 3. Module notes

### EC2 fleet

- Single variable map / YAML inventory
- Validations enforce io1/io2 presence, iops for provisioned volumes, at least one protected instance, no sc1/st1 root volumes, and distinct type/volume/size/key
- AZ spread via subnet list rotation when per-instance subnet is omitted

### Account A IAM

- `group1`: programmatic path, broker to roleB, CI user policy attached to `ci`
- `group2`: AdministratorAccess for assignment; optional login profiles
- `roleA`: admin except IAM
- `roleB`: only `sts:AssumeRole` on roleC

### Account B IAM

- Creates (optional) hardened bucket
- `roleC` trust + single-bucket policy

---

## 4. What I would do differently in a real org

1. Replace IAM users entirely with Identity Center + OIDC.
2. Put CI permissions on a **role**, not a user policy.
3. Use permission boundaries + SCPs around roleA-style admin.
4. Split root module into separately pipelines state machines (network / iam / compute).
5. Prefer ECS/EKS+ASG over hand-managed EC2 for app tiers; keep inventory EC2 only for true snowflakes.
6. Adopt S3 native state locking (`use_lockfile`) when all clients are on Terraform versions that support it — DynamoDB locking remains valid and matches this assignment.

---

## 5. Reviewer checklist

- [ ] `make reviewer-validate` passes (fmt + validate + contract checks)
- [ ] `make sandbox-up` works in a sandbox AWS account (IAM-only)
- [ ] `NOTES.md` §1 answers Tasks 1–5 directly
- [ ] ADRs in `docs/adr/` match the implemented trust/state/compute stance
- [ ] Outputs expose instance maps, role ARNs, and CI policy JSON
- [ ] Task 5 example matches the live Account B module intent
- [ ] `make sandbox-down` cleans up
