# Continuous integration and branch protection

CI is the definitive quality gate (see [ADR-0008](adr/0008-ai-first-guardrails.md)). Local Git hooks ([git-hooks.md](git-hooks.md)) give faster feedback, but nothing merges without a green CI.

## Workflow

`.github/workflows/ci.yml` runs on pull requests targeting `main` and on pushes to `main`. Dependencies are installed with `pnpm install --frozen-lockfile` using the Node.js version from `.nvmrc` and the pnpm version from the `packageManager` field. Third-party actions are pinned to commit SHAs.

| Check (job name)      | What it runs                                                              |
| --------------------- | ------------------------------------------------------------------------- |
| `Lint`                | `pnpm format:check` and `pnpm lint`                                       |
| `Typecheck`           | `pnpm typecheck`                                                          |
| `Test`                | `pnpm test`                                                               |
| `Build`               | `pnpm build`                                                              |
| `Repository hygiene`  | `scripts/check-public-repo-hygiene.sh`                                    |
| `Commit messages`     | commitlint over every commit of the pull request (pull requests only)     |
| `Secret scan`         | gitleaks over the full history, from a pinned and checksum-verified build |
| `Dependency audit`    | `pnpm audit --audit-level=high`                                           |

The job names are the required status checks of `main`. Renaming a job requires updating the branch protection at the same time.

Pull requests are merged with a merge commit, so no commit is rewritten and every commit message must be a valid Conventional Commit.

## Branch protection

The `main` branch is protected with these rules. They are applied in the GitHub repository settings, as the `protect-main` ruleset and as a classic branch protection rule (they are not versioned in code), so update this section whenever the settings change:

- Pull request required; no direct pushes, no force pushes and no branch deletion. The rules also apply to administrators.
- All eight checks above must pass, and the branch must be up to date with `main`.
- All conversations must be resolved.
- Merge commits are the only enabled merge method, so linear history is not required.
- **Required approvals: zero for now.** GitHub does not let an author approve their own pull request and there is a single maintainer. Revisit this when there is a second reviewer.

## CodeRabbit

CodeRabbit is an advisory review layer for pull requests that are not drafts and target `main`. It posts a summary and review comments, and it does not replace CI or human review.

- Configuration: `.coderabbit.yaml`.
- It never requests changes and its check is **not** a required status check, so an outage or a rate limit does not block merging.
- Only `pnpm-lock.yaml` is excluded from review, because pnpm generates it. Application code, migrations, CI workflows, agent instructions and security configuration are never excluded.
- Out of scope for now: the CodeRabbit coding agent, automatic fixes or commits, auto-merge and Verify/Security.
