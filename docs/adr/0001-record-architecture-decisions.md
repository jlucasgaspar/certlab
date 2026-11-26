# 0001. Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

Certlab is built largely by AI agents (tickets in Linear, PRs by agents, human review). Agents and future contributors need to know not just *what* the system looks like but *why*, or they will "fix" deliberate choices. The project is also meant to produce technical articles about its decisions.

## Decision

Record every significant architectural decision as a numbered ADR in `docs/adr/`, using the template in that folder. `docs/design.md` describes the current system and links to the ADRs. Agents read both before proposing structural changes.

## Consequences

- Decisions are discoverable and reviewable in PRs like code.
- Changing a decision means writing a superseding ADR, which forces the trade-off to be made explicit.
- ADRs double as drafts for dev.to / LinkedIn posts.

## Alternatives considered

- **Single design document only** — loses the history and the reasoning per decision.
- **Notion / Linear docs** — not versioned with the code, invisible to agents working in the repo.
