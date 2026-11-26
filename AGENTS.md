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

## Public repository hygiene

- Never commit credentials, OAuth tokens, private workspace identifiers, personal filesystem paths, or machine-specific agent configuration.
- Keep personal MCP servers, private issue-tracker settings, and client-specific permissions in ignored local files.
- Shared configuration must be portable for an unaffiliated contributor cloning the repository on a clean machine.
- Run `scripts/check-public-repo-hygiene.sh` before committing changes to agent configuration or maintainer tooling.
- Follow `docs/maintainer-local-setup.md` when configuring private integrations.
