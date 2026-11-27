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
| `Terraform`           | `scripts/validate-terraform.sh` with a pinned, checksum-verified Terraform |

All nine jobs are required status checks of `main`. The `Terraform` job validates the Terraform code without AWS credentials and never runs `plan` or `apply`.

The job names are the required status checks of `main`. Renaming a job requires updating the branch protection at the same time.

Pull requests are merged with a merge commit, so no commit is rewritten and every commit message must be a valid Conventional Commit.

## Branch protection

The `main` branch is protected with these rules. They are applied in the GitHub repository settings, as the `protect-main` ruleset and as a classic branch protection rule (they are not versioned in code), so update this section whenever the settings change:

- Pull request required; no direct pushes, no force pushes and no branch deletion.
- All nine checks above must pass, and the branch must be up to date with `main`.
- All conversations must be resolved.
- At least one approval from a Code Owner (`.github/CODEOWNERS`), and a new push after the approval dismisses it.
- Merge commits are the only enabled merge method, so linear history is not required.
- The classic branch protection rule keeps zero required approvals and enforces administrators. The approval requirement lives only in the ruleset, because the classic rule has no bypass.
- **Maintainer bypass.** GitHub does not let an author approve their own pull request, and the maintainer is the only Code Owner. The repository admin role is therefore a bypass actor in `pull_request` mode so the maintainer can merge. Agents never use it. See [repository-security.md](repository-security.md) for the reasoning, the access model, Actions settings and the secrets inventory.

## CodeRabbit

CodeRabbit is an advisory review layer for pull requests that are not drafts and target `main`. It posts a summary and review comments, and it does not replace CI or human review.

- Configuration: `.coderabbit.yaml`.
- It never requests changes and its check is **not** a required status check, so an outage or a rate limit does not block merging.
- Only `pnpm-lock.yaml` is excluded from review, because pnpm generates it. Application code, migrations, CI workflows, agent instructions and security configuration are never excluded.
- Pull requests opened by Renovate are reviewed like any other. Filtering by author or label would skip whole pull requests, including changes to manifests and CI workflows, so the only exclusion is `pnpm-lock.yaml`.
- Out of scope for now: the CodeRabbit coding agent, automatic fixes or commits, auto-merge and Verify/Security.

## Discord notifications

`.github/workflows/discord-pr-notifications.yml` posts to Discord when a pull request targeting `main` is opened and when it is merged. Closing without merging, and every other event, is ignored.

- It uses `pull_request_target` so the job can read the `DISCORD_WEBHOOK_URL` secret on a public repository. It never checks out or runs pull request code, and it declares `permissions: {}`. Do not add a checkout step to it.
- The webhook URL exists only as the `DISCORD_WEBHOOK_URL` GitHub Actions secret. Create an incoming webhook in the target channel and store its URL there.
- A Discord outage or rate limit fails the `Notify Discord` job with an error annotation. The job is **not** a required status check, so it never blocks merging.
- Out of scope: deploy, push, comment, review and CI notifications, and Discord bots.

## Dependency updates

Renovate keeps dependencies current. The configuration and its schedule are documented in `renovate.json5`:

- Weekly, before 09:00 UTC on Mondays, including lock file maintenance for `pnpm-lock.yaml`.
- Non-major updates are grouped in one pull request; each major update gets its own.
- Automerge is disabled. Renovate pull requests go through the same required checks and are merged by a maintainer.
- TypeScript stays below 6.1 until typescript-eslint supports it.
- The gitleaks version in `.github/workflows/ci.yml` is paired with a checksum, so it is updated by hand together with the checksum.
