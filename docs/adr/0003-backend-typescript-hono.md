# 0003. Backend in TypeScript with Hono, runtime-agnostic

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

The backend serves auth, the catalog, lab sessions with server-side answer validation, progress and review. It must cost close to nothing in stage, and production should be able to run on a regular server. We want contracts shared with the clients (ADR-0002).

We considered running stage on an always-on EC2 instance that shuts itself down when idle. Stopping on idle is easy (CloudWatch alarm action), but starting again on demand is not: the first request would need a separate "waker" function and would wait 30–60 s for boot. That is a homemade scale-to-zero with a worse cold start, and it conflicts with studying on the phone at any time. A small always-on spot instance costs only a few dollars a month, so auto-stop saves very little.

## Decision

- **TypeScript (strict) on Node.js LTS**, framework **Hono**.
- The app is written once and exposed through thin entry points: a Lambda adapter and a Node server adapter. No business code may depend on the runtime.
- **Stage runs on AWS Lambda + API Gateway HTTP API** (scales to zero natively, effectively free at our volume).
- **Production runtime is decided in phase 3** (Lambda, EC2 or Fargate) in its own ADR; switching is a deploy change, not a rewrite.
- Architecture: **modular monolith** (`auth`, `catalog`, `practice`, `progress`, `review`), each module owning its tables. Split into services only when a module has a real reason (e.g. the future AI tutor).
- Drizzle ORM + SQL migrations; zod at the edge; pino for logs.

## Consequences

- Same language and types across API and clients.
- Stage costs ~$0 and needs no start/stop automation.
- Lambda constraints apply in stage: cold starts (sub-second for a small Node bundle), connection handling to Postgres (use the Neon serverless driver), no in-memory state between requests. Code that respects those also runs fine on a server.
- Long-running work (future AI calls, batch jobs) must not live in request handlers; it goes to jobs/queues when needed.

## Alternatives considered

- **Always-on EC2 / spot in stage** — fine for learning servers, a few dollars a month; rejected as default because Lambda is cheaper and simpler for stage, and the code stays portable anyway.
- **EC2 with auto-stop + on-demand wake** — complexity without meaningful savings; poor first-request latency.
- **NestJS** — more structure and boilerplate than we need; heavier on Lambda.
- **Go / Python** — would require a separate contract pipeline (OpenAPI codegen) and split the codebase. Python may still appear later for AI/RAG work as a separate service.
