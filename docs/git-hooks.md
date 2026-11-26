# Git hooks and commit conventions

Local Git hooks give fast feedback before code reaches the remote. They are a convenience: **CI is the gate**, and nothing merges without it (see [ADR-0008](adr/0008-ai-first-guardrails.md)).

## Prerequisites

- Node.js 26 and pnpm (see `.nvmrc` and the `packageManager` field in `package.json`).
- [gitleaks](https://github.com/gitleaks/gitleaks) available on your `PATH`. It is a native binary, so it is not installed by pnpm.
  - macOS: `brew install gitleaks`
  - Other platforms: follow the [gitleaks installation guide](https://github.com/gitleaks/gitleaks#installing).

Lefthook and commitlint are installed by `pnpm install`, which also registers the hooks (`prepare` script).

## What runs

| Hook         | Checks                                                                                                |
| ------------ | ----------------------------------------------------------------------------------------------------- |
| `pre-commit` | Repository hygiene, Prettier on staged files, ESLint (`pnpm lint`, cached by Turborepo), gitleaks scan of staged changes |
| `commit-msg` | commitlint with Conventional Commits                                                                  |
| `pre-push`   | `typecheck` and `test` for workspaces affected by the branch (`turbo --affected`)                     |

The configuration lives in `lefthook.yml` and `commitlint.config.js`.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`, for example `feat(api): add health endpoint`. The header is limited to 100 characters.

Pull requests are merged with a merge commit, so no commit on a branch is rewritten and **every commit must be valid**. To check all commits of your branch against `main`:

```sh
pnpm lint:commits
```

CI reuses the same script. Merge commits created by GitHub are ignored by commitlint.

## Verifying the hooks

```sh
pnpm test:hooks
```

The script confirms that commitlint rejects an invalid message and that gitleaks detects a staged fake credential. The fake credential is generated at runtime in a throwaway repository; no secret-like value is stored in the repository.

## Skipping hooks

`git commit --no-verify` and `git push --no-verify` skip local hooks. Do not use them to get around a failing check; CI runs the same checks and will block the pull request.
