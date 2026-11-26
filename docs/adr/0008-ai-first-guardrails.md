# 0008. Guardrails from day one for AI-written code

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

Certlab's development loop is AI-first: an AI writes tickets in Linear, another AI implements them as pull requests, and a human reviews each PR and the process. A human reviewer cannot reliably catch everything in a high volume of generated code. Quality has to be enforced mechanically, before review, and from the very first PR — retrofitting tests and gates onto an AI-written codebase is far more expensive than starting with them.

## Decision

The following are part of phase 1, before the first AI-written PR:

- **Types:** TypeScript strict in every package; ESLint with type-aware rules; Prettier.
- **Tests:** Vitest unit tests; integration tests against a real Postgres for the API; an E2E smoke test of the core loop by the end of phase 2.
- **Local hooks (lefthook):** format + lint + secret scan on commit; Conventional Commits check on message; typecheck + affected tests on push.
- **CI (GitHub Actions), required for merge:** frozen install, lint, typecheck, tests, build, migration check, secret scan, dependency audit.
- **Repository protection:** protected `main`, PR required, green CI required, no force push.
- **Traceability:** every PR links a Linear ticket; PR template states what was tested and the risk.
- **Agent instructions:** `CLAUDE.md` / `AGENTS.md` at the root and per app, with commands, conventions and boundaries (e.g. never edit generated files, never weaken a lint rule to pass CI).
- **Observability baseline:** structured logs with request ids, error alarms.
- **Security baseline:** see `design.md` §8.

Hooks are a convenience; **CI is the gate**. Agents may skip local hooks, but nothing merges without CI.

## Consequences

- Slower start in phase 1; much faster, safer iteration afterwards.
- The human review focuses on intent, design and risk instead of style and obvious breakage.
- Phase 5 raises the bar (coverage thresholds, full E2E, AI code-review agents, tracing) on top of an existing baseline instead of starting from zero.

## Alternatives considered

- **Add quality tooling in a later hardening phase** — rejected: by then the AI-written code would already lack tests and conventions, and the cost of retrofitting grows with every merged PR.
