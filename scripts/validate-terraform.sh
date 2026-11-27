#!/usr/bin/env bash
# Deterministic Terraform checks: formatting, then init without a backend and validate for every root.
# Needs the Terraform version pinned in infra/.terraform-version. It never contacts AWS.

set -euo pipefail

cd "$(dirname "$0")/.."

expected="$(tr -d '[:space:]' < infra/.terraform-version)"
actual="$(terraform version | sed -n '1s/^Terraform v//p')"

if [[ "$actual" != "$expected" ]]; then
  printf 'Terraform %s is required (infra/.terraform-version), found %s.\n' "$expected" "${actual:-none}" >&2
  exit 1
fi

terraform fmt -check -recursive -diff infra

for root in infra/bootstrap/*/ infra/envs/*/; do
  printf '==> %s\n' "$root"
  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$root" validate
done

printf 'Terraform validation passed.\n'
