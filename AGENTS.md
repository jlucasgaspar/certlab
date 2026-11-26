# Certlab Agent Guidelines

## Project

Certlab is a gamified, mobile-first learning platform for technical certifications. This public repository contains the application source code, infrastructure, and technical documentation.

See `README.md` for the product overview, `docs/design.md` for the architecture, and `docs/roadmap.md` for the delivery plan.

## Repository language

- Write repository documentation in English, including `README.md`, `CLAUDE.md`, `AGENTS.md`, and `docs/design.md`.
- Keep code, identifiers, comments, commit messages, pull requests, and public GitHub issues in English.

## Product localization

- The product frontend must support English (`en`) and Brazilian Portuguese (`pt-BR`).
- English is the source and fallback locale.
- Do not hard-code user-facing interface copy; use translation keys and locale message catalogs.
- This requirement covers product UI. Certification and learning content may remain in its source language until content localization is specified separately.

## Architecture and quality

- Follow the accepted decisions in `docs/adr/` and the architecture in `docs/design.md`.
- Keep packages independent from apps. Shared domain packages must remain platform-agnostic.
- Do not weaken types, lint rules, tests, security checks, or CI gates merely to make a change pass.
- Keep changes scoped to the active Linear issue and report unrelated findings instead of silently expanding scope.

## Issue quality

- Follow `docs/issue-writing-standard.md` whenever creating, splitting, or materially refining an issue.
- Give each implementation issue one primary deliverable, explicit in-scope and out-of-scope boundaries, verifiable acceptance criteria, expected validation, and direct references.
- When an issue references a broad roadmap item, design section, or ADR, state the exact subset that applies.
- Do not invent a missing product or architecture decision. Resolve it first or create a focused discovery issue.

## Git workflow

- Branch names follow `lab-<number>-<short-description>`: lowercase, hyphen-separated, no user prefix. Example: `lab-8-monorepo-pnpm-turborepo`. Do not use the branch name Linear suggests.
- Commits follow Conventional Commits, in English. Example: `feat(api): add health endpoint`. Reference the Linear issue in the commit body when useful (`Refs: LAB-8`).
- Every pull request links its Linear issue and carries the issue key in the title. Example: `build: scaffold pnpm and Turborepo monorepo (LAB-8)`.
- Merge with a merge commit, which keeps the branch history. Every commit on the branch must be a valid Conventional Commit, because none is rewritten on merge; keep the branch history clean (no `wip` commits).

## Code conventions

- Do not use `index.ts` barrel files in backend code. Import from the file that defines the symbol (for example `./health/routes`) so imports stay easy to trace.
- Packages expose their public API through explicit subpath entries in the `exports` field of `package.json`, not through a catch-all `index`.
- Name files after their domain (`limits.ts`, `session-rules.ts`). Do not create generic `constants.ts` or `utils.ts` files.

## Public repository hygiene

- Never commit credentials, OAuth tokens, private workspace identifiers, personal filesystem paths, or machine-specific agent configuration.
- Keep personal MCP servers, private issue-tracker settings, and client-specific permissions in ignored local files.
- Shared configuration must be portable for an unaffiliated contributor cloning the repository on a clean machine.
- Run `scripts/check-public-repo-hygiene.sh` before committing changes to agent configuration or maintainer tooling.
- Follow `docs/maintainer-local-setup.md` when configuring private integrations.
