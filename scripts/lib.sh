#!/usr/bin/env bash
# Shared helpers for reviewer / sandbox scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX_DIR="${ROOT}/.sandbox"
SANDBOX_TFVARS="${SANDBOX_DIR}/terraform.tfvars"
SANDBOX_META="${SANDBOX_DIR}/meta.env"

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

ensure_sandbox_dir() {
  mkdir -p "${SANDBOX_DIR}"
}
