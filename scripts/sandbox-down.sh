#!/usr/bin/env bash
# Destroy the sandbox created by sandbox-up.sh.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
cd "${ROOT}"

[[ -f "${SANDBOX_TFVARS}" ]] || die "No .sandbox/terraform.tfvars — nothing to destroy (or run from the same clone)."

./scripts/preflight.sh sandbox

# shellcheck disable=SC1090
source "${SANDBOX_META}"
log "Destroying sandbox prefix: ${NAME_PREFIX}"

AUTO_APPROVE="${SANDBOX_AUTO_APPROVE:-0}"
DESTROY_ARGS=(-var-file="${SANDBOX_TFVARS}" -input=false)
if [[ "${AUTO_APPROVE}" == "1" ]]; then
  DESTROY_ARGS+=(-auto-approve)
fi

# If EC2 with prevent_destroy was enabled, warn clearly.
if grep -q 'enable_ec2[[:space:]]*=[[:space:]]*true' "${SANDBOX_TFVARS}"; then
  warn "EC2 was enabled. If destroy fails on ledger-a, set protected=false in inventory, apply, then re-run destroy."
fi

terraform init -backend=false -input=false >/dev/null
terraform destroy "${DESTROY_ARGS[@]}"

log "Sandbox destroyed. Removing .sandbox/ metadata."
rm -rf "${SANDBOX_DIR}"
log "Done."
