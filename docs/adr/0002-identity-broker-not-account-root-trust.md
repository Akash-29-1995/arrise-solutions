# ADR 0002 — Cross-account access via an explicit broker role

## Status

Accepted

## Context

Account B must allow Account A to access one S3 bucket. The easy pattern — trust `arn:aws:iam::ACCOUNT_A:root` — delegates authorization to every future identity policy change in Account A.

## Decision

- `roleB` in Account A may only call `sts:AssumeRole` on `roleC`.
- `roleC` in Account B trusts the **exact** `roleB` ARN, not Account A root.
- group1 humans/automation reach the bucket only by assuming `roleB` first.

## Consequences

- Clear audit path: User/OIDC → roleB → roleC → bucket.
- Expanding access is an intentional change to the broker, not an accidental side effect of granting admin in Account A.
- Slightly more moving parts than a single cross-account user policy — correct for least privilege.
