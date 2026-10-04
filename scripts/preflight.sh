#!/usr/bin/env bash
# Checks tools + (optionally) AWS identity before sandbox apply.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${1:-offline}" # offline | sandbox

require_cmd terraform

tf_version="$(terraform version -json 2>/dev/null | sed -n 's/.*"terraform_version":"\([^"]*\)".*/\1/p')"
if [[ -z "${tf_version}" ]]; then
  tf_version="$(terraform version | head -n1)"
fi
log "Terraform: ${tf_version}"

if [[ "${MODE}" == "sandbox" ]]; then
  require_cmd aws
  require_cmd python3

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    die "AWS credentials not usable. Export AWS_PROFILE / AWS_ACCESS_KEY_ID or run aws sso login."
  fi

  ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
  ARN="$(aws sts get-caller-identity --query Arn --output text)"
  REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-south-1}}"
  log "AWS account: ${ACCOUNT}"
  log "AWS identity: ${ARN}"
  log "AWS region hint: ${REGION}"
fi

log "Preflight OK (${MODE})"
