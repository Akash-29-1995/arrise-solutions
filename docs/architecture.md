# Architecture

Architect view of the assignment as one multi-account (or single-account reviewer) system.

**Run it:** see [`REVIEWER.md`](../REVIEWER.md) — offline validate, sandbox-up, or full remote-state path.

## High-level control / data plane

```mermaid
flowchart TB
  reviewer[Reviewer / CI] --> validate[fmt + validate]
  reviewer --> bootstrap[Bootstrap stack]
  bootstrap --> s3[(S3 state + KMS)]
  bootstrap --> ddb[(DynamoDB lock)]

  reviewer --> root[Root stack]
  root --> s3
  root --> ddb

  root --> ec2[ec2_fleet]
  root --> a[iam_account_a]
  root --> b[iam_account_b]

  a --> g1[group1 engine/ci]
  a --> g2[group2 alice/bob]
  a --> roleA[roleA admin except IAM]
  a --> roleB[roleB broker]
  b --> roleC[roleC]
  roleB -->|sts:AssumeRole exact trust| roleC
  roleC --> bucket[(one S3 bucket)]
```

## Identity path

```mermaid
sequenceDiagram
  participant CI as ci user (group1)
  participant B as roleB (Account A)
  participant C as roleC (Account B)
  participant S3 as Named bucket

  CI->>B: sts:AssumeRole
  B->>C: sts:AssumeRole (only permission on B)
  C->>S3: s3:* on one bucket ARN
```

Trusting Account A root instead of `roleB` would let any sufficiently privileged principal in A become a cross-account actor. Exact ARN trust keeps the broker explicit.

## Scale decision tree

```mermaid
flowchart TD
  start[Need compute?] --> q{Instances mostly identical?}
  q -->|No snowflakes| inv[Inventory map + ec2_fleet]
  q -->|Yes cattle| asg[Launch template + ASG module]
  inv --> split[Split state by account/env/workload]
  asg --> heal[ELB/EC2 health + instance refresh]
```

## Reviewer vs production topology

| Concern | Reviewer default | Production target |
|---------|------------------|-------------------|
| Accounts | Caller account for A and B | Separate A/B (+ org OU) |
| Credentials | Ambient AWS creds | Assume deploy roles / OIDC |
| Humans | IAM users (assignment) | Identity Center |
| CI | IAM user policy (assignment) | OIDC → role |
| State | Optional local or one S3 key | Per-account/env keys |
| Compute | Optional cheap inventory | ASG/ECS for app tiers |
