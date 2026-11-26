# 0002. One monorepo with three apps

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

Certlab has three deployables: an API, a web app (desktop + mobile web / PWA) and a native mobile app. They share the most important contract in the product — the shape of the seven question kinds and the API payloads — plus design tokens and domain logic (lab session queue, retry rules).

Development is AI-first: a single Linear ticket such as "add a field to Sequence questions" typically touches the API, the web and the app at once.

## Decision

Use **one monorepo** with pnpm workspaces and Turborepo:

- `apps/api`, `apps/web`, `apps/mobile`
- `packages/contracts` (zod schemas), `packages/core` (pure domain logic), `packages/tokens`, `packages/i18n` (shared locale definitions and message catalogs), `packages/ui-web`, `packages/config`
- `content/`, `infra/`, `docs/`

Packages never import from apps. `contracts`, `core`, and `i18n` stay free of platform dependencies (React, Hono, Node-only APIs) so every app can use them.

## Consequences

- One ticket → one atomic PR; the typechecker catches client/API drift inside that PR.
- One set of lint rules, hooks, CI workflows and agent instructions to maintain.
- Turborepo caching and affected-only tasks keep CI fast as the repo grows.
- Deploys stay independent: each app has its own pipeline triggered by changes to its paths.
- Risk: a careless change in a shared package affects every app — mitigated by CI running the dependents' tests.

## Alternatives considered

- **Three repositories (api, web, mobile)** — matches the deploy units, but every cross-cutting change becomes several coordinated PRs, contracts need publishing and versioning, and agents lose context between repos.
- **Two repositories (backend, frontend)** — same problem for any change that touches the API contract.
