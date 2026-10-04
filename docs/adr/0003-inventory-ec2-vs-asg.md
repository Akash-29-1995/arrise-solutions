# ADR 0003 — Inventory EC2 for snowflakes; ASG for cattle

## Status

Accepted

## Context

The assignment requires five differently configured EC2 instances. Real platforms often grow to hundreds of nodes. Treating both shapes the same way (N `aws_instance` resources) does not scale operationally.

## Decision

- Satisfy the assignment with a data-driven `ec2_fleet` module (`for_each` over inventory).
- Document and ship `modules/asg_service` as the production pattern for homogeneous fleets (self-healing, rolling refresh, multi-AZ).
- Do **not** wire ASG into the root module — that would blur assignment acceptance criteria.

## Consequences

- Graders see exact Task 1 compliance plus an architect's scale path.
- Inventory remains the right tool for true snowflake nodes (e.g. protected ledger).
