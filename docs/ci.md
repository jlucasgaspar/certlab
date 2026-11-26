# Continuous integration and branch protection

CI is the definitive quality gate (see [ADR-0008](adr/0008-ai-first-guardrails.md)). Local Git hooks ([git-hooks.md](git-hooks.md)) give faster feedback, but nothing merges without a green CI and a human approval.

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

See the rules applied to `main` in the repository settings. The deterministic checks above and one human approval are required.

## CodeRabbit

CodeRabbit is an advisory review layer for pull requests that are not drafts and target `main`. It posts a summary and review comments, and it does not replace CI or the human approval.

- Configuration: `.coderabbit.yaml`.
- It never requests changes and its check is **not** a required status check, so an outage or a rate limit does not block merging.
- Only `pnpm-lock.yaml` is excluded from review, because pnpm generates it. Application code, migrations, CI workflows, agent instructions and security configuration are never excluded.
- Out of scope for now: the CodeRabbit coding agent, automatic fixes or commits, auto-merge and Verify/Security.
