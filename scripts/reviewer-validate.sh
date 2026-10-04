#!/usr/bin/env bash
# Offline / CI-safe validation path for reviewers (no AWS mutations).
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
cd "${ROOT}"

./scripts/preflight.sh offline
./scripts/verify-requirements.sh

log "terraform fmt -check -recursive"
terraform fmt -check -recursive

log "root: init -backend=false && validate"
terraform init -backend=false -input=false
terraform validate

log "bootstrap/remote-state: init -backend=false && validate"
terraform -chdir=bootstrap/remote-state init -backend=false -input=false
terraform -chdir=bootstrap/remote-state validate

log "OK: offline validation + requirement contracts passed"
echo "Next:"
echo "  • Sandbox (your AWS account, IAM-only):  make sandbox-up"
echo "  • Docs:                                  open REVIEWER.md"
