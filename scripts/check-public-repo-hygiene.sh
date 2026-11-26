#!/usr/bin/env bash

set -euo pipefail

private_paths=(
  ".mcp.json"
  ".codex/config.toml"
  ".claude/settings.local.json"
  ".claude/hooks-local"
  "CLAUDE.local.md"
  ".claude/hooks/guard-linear-issue-write.mjs"
)

tracked_private_paths=()

for path in "${private_paths[@]}"; do
  if [[ -n "$(git ls-files -- "$path" "$path/**")" ]]; then
    tracked_private_paths+=("$path")
  fi
done

if ((${#tracked_private_paths[@]} > 0)); then
  printf 'Private maintainer files must not be tracked:\n' >&2
  printf '  %s\n' "${tracked_private_paths[@]}" >&2
  exit 1
fi

personal_path_pattern='(/Users/[^/]+/|/home/[^/]+/|~/(www|ze)/)'

if matches=$(git grep -n -E "$personal_path_pattern" -- ':!scripts/check-public-repo-hygiene.sh'); then
  printf 'Personal filesystem paths found in tracked files:\n%s\n' "$matches" >&2
  exit 1
fi

private_integration_pattern='(certlab-workspace|mcp\.linear\.app|team key.*LAB|team with key.*LAB)'

if matches=$(git grep -n -E "$private_integration_pattern" -- ':!scripts/check-public-repo-hygiene.sh'); then
  printf 'Private integration details found in tracked files:\n%s\n' "$matches" >&2
  exit 1
fi

printf 'Public repository hygiene check passed.\n'
