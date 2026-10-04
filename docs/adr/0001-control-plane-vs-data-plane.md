# ADR 0001 — Separate control plane (state) from data plane (workloads)

## Status

Accepted

## Context

Terraform needs a place to store state before it can manage application resources. Putting the state bucket in the same root module that consumes it creates a circular operational dependency and a dangerous blast radius (a bad apply can orphan the only copy of state).

## Decision

Bootstrap remote state (S3 + KMS + DynamoDB lock) in `bootstrap/remote-state` as its own stack. The assignment root module consumes that backend via partial configuration (`backend.hcl`).

## Consequences

- Reviewers can skip remote state entirely with `terraform init -backend=false` for sandbox demos.
- Production keeps durable, locked, encrypted state with an independent lifecycle.
- Slightly more ceremony than a single folder — acceptable for an architect-level design.
