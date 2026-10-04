#!/usr/bin/env bash
# Offline assignment contract checks — no AWS calls.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
cd "${ROOT}"

failures=0
pass() { printf '  [PASS] %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*"; failures=$((failures + 1)); }

log "Verifying assignment contracts offline"

INV="inventory/dev-instances.yaml"
CHEAP="inventory/dev-instances-cheap.yaml"

count_instances() {
  # Top-level YAML keys that look like instance names (no leading whitespace).
  grep -E '^[a-zA-Z0-9_-]+:$' "$1" | wc -l | tr -d ' '
}

for file in "${INV}" "${CHEAP}"; do
  if [[ ! -f "${file}" ]]; then
    fail "missing ${file}"
    continue
  fi
  count="$(count_instances "${file}")"
  if [[ "${count}" -eq 5 ]]; then
    pass "$(basename "${file}"): 5 instances"
  else
    fail "$(basename "${file}"): expected 5 instances, got ${count}"
  fi
  if grep -Eq 'root_volume_type:[[:space:]]*io[12]' "${file}"; then
    pass "$(basename "${file}"): io1/io2 present"
  else
    fail "$(basename "${file}"): missing io1/io2"
  fi
  if grep -Eq 'protected:[[:space:]]*true' "${file}"; then
    pass "$(basename "${file}"): protected instance present"
  else
    fail "$(basename "${file}"): missing protected: true"
  fi
  if grep -Eq 'root_volume_type:[[:space:]]*(sc1|st1)' "${file}"; then
    fail "$(basename "${file}"): sc1/st1 cannot be root volumes"
  else
    pass "$(basename "${file}"): no sc1/st1 roots"
  fi
done

if grep -q 'for_each' modules/ec2_fleet/main.tf && grep -q 'prevent_destroy' modules/ec2_fleet/main.tf; then
  pass "Task1: for_each + prevent_destroy in ec2_fleet"
else
  fail "Task1: ec2_fleet missing for_each or prevent_destroy"
fi

if grep -q 'instance_ids_by_name' outputs.tf && grep -q 'private_ips_by_name' outputs.tf; then
  pass "Task1: required outputs present"
else
  fail "Task1: missing instance map outputs"
fi

if grep -q 'backend "s3"' backend.tf && [[ -f bootstrap/remote-state/main.tf ]]; then
  pass "Task2: S3 backend + bootstrap stack present"
else
  fail "Task2: missing S3 backend or bootstrap stack"
fi
if grep -q 'aws_dynamodb_table' bootstrap/remote-state/main.tf; then
  pass "Task2: DynamoDB lock table defined"
else
  fail "Task2: DynamoDB lock table missing"
fi

if grep -q 'roleA' modules/iam_account_a/main.tf && grep -q 'roleB' modules/iam_account_a/main.tf; then
  pass "Task3: Account A roles present"
else
  fail "Task3: Account A roles missing"
fi

if grep -q 'TrustExactRoleBOnly\|trusted_role_b_arn' modules/iam_account_b/main.tf && grep -q 'role/roleB' examples/task5-fixed-snippet.tf; then
  pass "Task3/5: roleC trusts exact roleB"
else
  fail "Task3/5: roleC → roleB trust pattern missing"
fi

if [[ -f policies/ci-policy.json ]] && grep -q 'ecr:PutImage' policies/ci-policy.json && grep -q 'ecs:UpdateService' policies/ci-policy.json; then
  pass "Task4: CI policy covers ECR push + ECS update"
else
  fail "Task4: CI policy incomplete"
fi

if grep -Eq 's3:PutObject|"s3:\*"' policies/ci-policy.json; then
  fail "Task4: CI policy should not allow S3 writes / s3:*"
else
  pass "Task4: CI policy stays read-only for artifacts"
fi

if grep -q 'user/roleB' NOTES.md && grep -q 'role/roleB' NOTES.md; then
  pass "Task5: NOTES explain user vs role ARN bug"
else
  fail "Task5: NOTES missing trust ARN explanation"
fi

for f in REVIEWER.md config/sandbox.tfvars scripts/sandbox-up.sh scripts/sandbox-down.sh docs/adr/0001-control-plane-vs-data-plane.md; do
  if [[ -f "${f}" ]]; then pass "UX/ADR: ${f}"; else fail "UX/ADR: missing ${f}"; fi
done

echo
if [[ "${failures}" -gt 0 ]]; then
  die "${failures} requirement check(s) failed"
fi
log "All offline requirement checks passed"
