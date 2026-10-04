# Arrise DevOps Infrastructure Assignment

Architect-level Terraform answer for the DevOps / Infrastructure Engineer brief — designed so a reviewer can **understand the decisions** and **run the stack** without tribal knowledge.

## Start here

### Reviewers

**Open [`REVIEWER.md`](REVIEWER.md)** — three copy-paste paths:

| Path | Command | Needs AWS? |
|------|---------|------------|
| Offline validate | `make reviewer-validate` | No |
| Sandbox (IAM) | `make sandbox-up` | Yes (your account) |
| Sandbox + EC2 | `SANDBOX_WITH_EC2=1 make sandbox-up` | Yes |
| Teardown | `make sandbox-down` | Yes |

### Architecture reading order

1. [`REVIEWER.md`](REVIEWER.md) — how to run / grade  
2. [`NOTES.md`](NOTES.md) — direct assignment answers + trade-offs  
3. [`docs/architecture.md`](docs/architecture.md) — diagrams  
4. [`docs/adr/`](docs/adr/) — control plane, identity broker, compute scale  

---

## What this is (one paragraph)

A small **landing-zone style** design: inventory-driven EC2 (Task 1), bootstrapped remote state with locking (Task 2), multi-account IAM with an explicit cross-account broker (Task 3), a custom least-privilege CI policy (Task 4), and a corrected trust/permissions example (Task 5). Production deltas (no long-lived access keys, Identity Center, ASG for cattle) are called out on purpose — that is the architect bar.

---

## Repository map

```text
REVIEWER.md                 ← reviewer entrypoint
NOTES.md                    ← assignment answers + rationale
config/sandbox.tfvars       ← safe sandbox defaults
scripts/
  reviewer-validate.sh      ← offline fmt/validate + contracts
  sandbox-up.sh / down.sh   ← one-command live sandbox
  verify-requirements.sh    ← offline Task 1–5 contract checks
modules/ec2_fleet           ← Task 1
modules/iam_account_a|b     ← Tasks 3–4
bootstrap/remote-state      ← Task 2 foundation
modules/asg_service         ← beyond brief (homogeneous fleets)
docs/adr/                   ← architecture decision records
```

---

## Design principles

1. **Blast radius** — state, IAM, and compute are separable.  
2. **Data over duplication** — fleet size is inventory, not N resource blocks.  
3. **Explicit trust** — Account B trusts `roleB`, never Account A root.  
4. **Least privilege by construction** — CI gets a custom policy, not PowerUser.  
5. **Runnable** — offline contracts + sandbox prefixes so shared accounts do not collide.

---

## Task index

| Task | Where |
|------|--------|
| 1 EC2 fleet | `modules/ec2_fleet`, `inventory/` |
| 2 Remote state | `bootstrap/remote-state`, `backend.tf` |
| 3 Multi-account IAM | `modules/iam_account_a`, `modules/iam_account_b` |
| 4 CI least privilege | module policy + `policies/ci-policy.json` |
| 5 Bugfix | `examples/task5-fixed-snippet.tf` + `NOTES.md` |

---

## CI

GitHub Actions runs the same offline path as `make reviewer-validate` on push/PR.
