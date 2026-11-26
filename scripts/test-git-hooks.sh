#!/usr/bin/env bash
# Verifies that the commit message and secret scanning checks reject bad input.
# Uses a throwaway repository and generates the fake secret at runtime, so no
# secret-like value is stored in this repository.

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# 1. commitlint rejects an invalid message and accepts a valid one.
if printf 'update stuff\n' | (cd "$repo_root" && pnpm exec commitlint) >/dev/null 2>&1; then
  fail 'commitlint accepted an invalid commit message'
fi
printf 'feat(api): add health endpoint\n' | (cd "$repo_root" && pnpm exec commitlint) >/dev/null ||
  fail 'commitlint rejected a valid commit message'

# 2. gitleaks detects a staged fake credential.
command -v gitleaks >/dev/null || fail 'gitleaks is not installed (see docs/git-hooks.md)'

suffix=$(node -e "
const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const bytes = require('node:crypto').randomBytes(16);
process.stdout.write(Array.from(bytes, (b) => chars[b % chars.length]).join(''));
")
git -C "$workdir" init -q
printf 'aws_access_key_id = AKIA%s\n' "$suffix" >"$workdir/fixture.env"
git -C "$workdir" add fixture.env

if (cd "$workdir" && gitleaks git --staged --redact --no-banner) >/dev/null 2>&1; then
  fail 'gitleaks did not detect the staged fake secret'
fi

printf 'Git hook checks behave as expected.\n'
