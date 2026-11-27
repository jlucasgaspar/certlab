# Repository access, reviews and secrets

Certlab is a public repository on a personal GitHub account. Anyone can read it, fork it and propose changes. Only people with granted access can change settings, create secrets, push or merge. This page records the controls that are configured in GitHub (they are not versioned in code), so update it whenever the settings change. See [ci.md](ci.md) for the checks and [ADR-0008](adr/0008-ai-first-guardrails.md) for the decision behind human review.

## Access model

- The maintainer (`@jlucasgaspar`) is the only collaborator, with admin access. There are no pending invitations and no deploy keys.
- Treat anyone with write access as able to use the repository secrets, because they can change a workflow on a branch. Grant write access only by named exception, with a justification and a review date, and record it here.
- Review the installed GitHub Apps and other integrations under **Settings → Integrations**. Each one must be limited to this repository and to the permissions it needs. Remove the ones that are not used.
- The maintainer reviewed the installed GitHub Apps and integrations on 2026-11-27 and confirmed they are limited to this repository.
- Agents authenticate with the maintainer's credentials and never use the maintainer bypass described below.

## Review of changes to `main`

The `protect-main` ruleset applies to `main`.

Settings (applied 2026-11-27):

- Pull request required, with at least one approval from a Code Owner. `.github/CODEOWNERS` assigns every path to `@jlucasgaspar`, including the file itself and `.github/`.
- A new commit after the approval dismisses it, and the latest push must be approved.
- All review conversations resolved.
- The nine required checks from [ci.md](ci.md), with the branch up to date.
- Merge commits only, no force pushes and no branch deletion.
- One bypass actor: the repository admin role, in `pull_request` mode (see below).

### Accepted deviation: maintainer bypass

GitHub does not let an author approve their own pull request, and the maintainer is both the only Code Owner and the author of every pull request. Requiring approval without an exception would block all merges.

Decision (2026-11-27), the repository **admin role** is a bypass actor of the ruleset in `pull_request` mode, so the maintainer can merge a pull request that has no approval. This weakens the "every change is approved by a human other than the author" control from [ADR-0008](adr/0008-ai-first-guardrails.md) to "the maintainer reviews and merges every pull request". Checks, conversation resolution and the other rules still apply to bypassing merges as far as GitHub allows.

Rules for using it:

- Only the maintainer merges. Agents and automation never merge and never use the bypass.
- Remove the bypass actor and add the reviewer to `CODEOWNERS` when a second reviewer, or a separate review account with its own access, exists. This is not a priority now.

## GitHub Actions

- The default `GITHUB_TOKEN` is read-only and Actions cannot create or approve pull requests.
- Every workflow declares `permissions` explicitly. `ci.yml` uses `contents: read`; the Discord workflow uses `permissions: {}`.
- Third-party actions are allowed only from an explicit list (`actions/checkout`, `actions/setup-node`, `pnpm/action-setup`) and must be pinned to a full commit SHA. GitHub enforces the SHA pinning.
- Workflows from forks wait for maintainer approval when the author is a first-time contributor. Fork pull requests handled by `pull_request` workflows (CI) receive no secrets and a read-only token. The only exception is the Discord workflow: `pull_request_target` runs the workflow file from `main` with the secret available, which is safe only because it never runs pull request code.
- `discord-pr-notifications.yml` uses `pull_request_target` and is the only workflow that reads a secret. It never checks out or runs code from the pull request. No workflow may combine a secret with code from an untrusted pull request.

## Security features

| Feature                        | State                                  |
| ------------------------------ | -------------------------------------- |
| Secret scanning                | Enabled                                |
| Push protection                | Enabled                                |
| Dependency graph               | Enabled (public repository default)    |
| Dependabot alerts              | Enabled                                |
| Dependabot security updates    | Enabled                                |
| Private vulnerability reports  | Enabled (see [SECURITY.md](../SECURITY.md)) |

Renovate keeps dependencies current (see [ci.md](ci.md)). Dependabot security updates only react to advisories.

## Secrets and variables inventory

Record the name, purpose, scope, consumer, owner and rotation procedure. Never record a value. Credentials live only as GitHub Actions secrets: never as Actions variables, `.env` files, logs, artifacts, documentation or committed content.

| Name                  | Type   | Purpose                                              | Scope      | Consumer                                         | Owner         |
| --------------------- | ------ | ---------------------------------------------------- | ---------- | ------------------------------------------------ | ------------- |
| `DISCORD_WEBHOOK_URL` | Secret | Incoming webhook for pull request open/merge notices | Repository | `.github/workflows/discord-pr-notifications.yml` | `@jlucasgaspar` |

There are no Actions variables.

### Rotating or revoking `DISCORD_WEBHOOK_URL`

If the URL may have leaked (pasted in chat, an issue, a log or anywhere public), revoke it first. Deleting the webhook is what invalidates the old URL.

1. In Discord, open the channel settings, then **Integrations → Webhooks**, and **delete** the old webhook.
2. Create a new webhook in the same channel.
3. Store the new URL with `gh secret set DISCORD_WEBHOOK_URL`, pasting it at the prompt so it stays out of shell history.
4. Open a pull request and confirm that the notification arrives and the workflow log shows no URL.

For a routine rotation without suspected exposure, create the new webhook and update the secret first, then delete the old webhook once the new one is confirmed. Do not rotate only to produce evidence.

## Periodic review

Review this page, the collaborators, the installed apps, the secret inventory and the Actions settings before each roadmap phase wrap-up and after any change of maintainers.
