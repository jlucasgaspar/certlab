# Certlab — System Design

> Status: draft · Last updated: 2026-11-27
> Product vision lives in [vision.md](vision.md); setup and commands live in the root [README](../README.md). Delivery plan lives in [roadmap.md](roadmap.md). Individual decisions live in [adr/](adr/README.md).

This document describes how Certlab is built: the pieces, how they talk to each other, where they run and which rules every change must follow. It is the map; the ADRs are the reasoning behind each road.

---

## 1. Context

Certlab is a gamified, mobile-first learning platform for technical certifications ("Duolingo for certs"). The first catalog is cloud certifications (AWS, Google Cloud, Azure); the first exam we build end to end is **AWS Cloud Practitioner (CLF-C02)**.

Two facts shape the architecture more than anything else:

1. **Three surfaces, one product.** Desktop web, mobile web (PWA) and a native app in the stores. The mobile layout is the source of truth; desktop is a responsive adaptation. Shared tokens and components are maintained in `packages/tokens` and `packages/ui-web` as they are ported into the repository.
2. **AI-first development.** One AI writes tickets in Linear, another AI implements them as pull requests, and a human (Zé) reviews every PR and the process itself. Quality therefore has to be enforced by tooling — types, tests, lint, hooks, CI gates, branch protection — from the first commit, not added later. See [ADR-0008](adr/0008-ai-first-guardrails.md).

Guiding constraint: **start simple, keep costs near zero in stage, and keep every choice reversible.**

---

## 2. Architecture overview

```text
                     ┌────────────────────────────┐
  Browser (desktop,  │  CloudFront + S3           │  static SPA (apps/web)
  mobile web / PWA) ─┤  app.<domain>              │
                     └────────────────────────────┘
                                  │ HTTPS (JSON, cookies)
  Native app ─────────────────────┤ HTTPS (JSON, bearer token)
  (apps/mobile, phase 4)          ▼
                     ┌────────────────────────────┐
                     │  API  (apps/api, Hono)     │  api.<domain>
                     │  stage: Lambda + HTTP API  │
                     │  prod:  decided in phase 3 │
                     └────────────────────────────┘
                                  │ SQL
                     ┌────────────────────────────┐
                     │  PostgreSQL                │
                     │  stage: Neon (free)        │
                     │  prod:  RDS (phase 3)      │
                     └────────────────────────────┘

  Later (post-MVP): AI service (LLM + RAG over pgvector), background jobs, queues.
```

- The web app is a **static SPA**; no server rendering. See [ADR-0004](adr/0004-web-vite-react-spa.md).
- The API is a **modular monolith** written in TypeScript with Hono, kept runtime-agnostic so the same code runs on Lambda (stage) and on a regular Node server (prod, if we choose). See [ADR-0003](adr/0003-backend-typescript-hono.md).
- One PostgreSQL database. Postgres also covers future needs (JSONB for question payloads, `pgvector` for RAG) without new infrastructure.

---

## 3. Repository layout

One monorepo, three deployable apps, shared packages. See [ADR-0002](adr/0002-monorepo.md).

```text
certlab/
├── apps/
│   ├── api/          Hono API (auth, catalog, practice, progress, review)
│   ├── web/          Vite + React SPA (desktop + mobile web / PWA)
│   └── mobile/       Native app (phase 4; Expo or Capacitor — ADR-0007)
├── packages/
│   ├── contracts/    zod schemas: API requests/responses, the 7 question kinds
│   ├── core/         pure domain logic shared by clients (lab session queue, retry rules)
│   ├── tokens/       design tokens (colors, type, spacing, radii, motion) as TS + CSS
│   ├── i18n/         shared locale definitions and message catalogs (en, pt-BR)
│   ├── ui-web/       React DOM components ported from the design system
│   └── config/       shared tsconfig, eslint, vitest presets
├── content/          question bank as versioned files (ADR-0009)
├── infra/            Terraform (modules + envs/stage + envs/prod)
└── docs/             design.md, roadmap.md, adr/, articles/ (dev.to drafts)
```

Tooling: **pnpm workspaces + Turborepo** (affected-only builds and tests in CI).

Dependency rule: `apps/*` may depend on `packages/*`; packages never depend on apps; `contracts`, `core`, and `i18n` have no runtime dependency on React, Hono or any platform API, so they work in the API, the web and the native app alike.

---

## 4. Backend

### 4.1 Stack

| Concern | Choice |
|---|---|
| Language | TypeScript (strict) on Node.js LTS |
| HTTP framework | Hono (adapters for AWS Lambda and Node server) |
| Validation & contracts | zod, shared via `packages/contracts`; OpenAPI generated from the routes |
| ORM & migrations | Drizzle ORM + drizzle-kit (SQL migrations checked into git) |
| Database driver | Neon serverless driver in stage; `pg` pool on a long-running server |
| Auth | Better Auth (ADR-0005) |
| Logging | pino, structured JSON to stdout |
| Tests | Vitest (unit + integration against a real Postgres) |

### 4.2 Modules

Each module owns its routes, service logic and tables. Modules talk to each other through their service interfaces, never through each other's tables.

| Module | Responsibility |
|---|---|
| `auth` | Sign up, log in, OAuth (Google, GitHub; Apple before store release), sessions, password reset, account deletion |
| `catalog` | Providers, exams, chapters, labs, questions (read-mostly, seeded from `content/`) |
| `practice` | Start a lab session, serve questions, **validate answers on the server**, return explanation |
| `progress` | XP, streaks, lab completion, levels |
| `review` | Errata (missed questions) and Retest; MVP uses simple rules, FSRS later |

Answer validation happens on the server. The client never receives the correct answer before submitting, which keeps the thesis defense (mock exam) honest and keeps scoring logic in one place.

### 4.3 Data model (draft)

```text
user ─┬─< account / session            (Better Auth tables)
      ├─< user_exam                    (exams the user is studying, current exam)
      ├─< lab_session ─< answer_attempt
      ├─< review_item                  (errata: question, misses, state, due_at)
      ├─< xp_event
      └── streak                       (current, longest, last_active_date, timezone)

provider ─< exam ─< chapter ─< lab ─< question
question: id, lab_id, kind, prompt, payload (jsonb), answer (jsonb), explanation, version
```

- `question.kind` is one of: `multiple_choice`, `choose_two`, `sequence`, `match_pairs`, `complete_code`, `exam_scenario`, `diagram`. `payload` and `answer` are JSONB whose shape is defined per kind by a zod discriminated union in `packages/contracts`.
- **`answer_attempt` is an append-only event log** (user, question, question version, submitted answer, correct, time spent, timestamp). It is the data foundation for adaptive review, analytics and the future AI tutor. We record it from the first lab, even before we use it.
- Database indexes are query-driven. Primary keys and unique constraints enforce correctness; every additional index must serve a documented filter, join, ordering or foreign-key access pattern. Avoid speculative indexes because each one adds write, storage and maintenance cost.

### 4.4 API style

- REST + JSON under `/v1`. Breaking changes require a new version once the native app ships (old app versions stay in the wild).
- Errors use one shape: `{ error: { code, message, details? } }`.
- Every request gets a request id, propagated to logs.

---

## 5. Frontend

### 5.1 Web (`apps/web`)

- Vite + React + TypeScript, TanStack Router, TanStack Query for server state.
- PWA: installable, app icon and splash from the design system assets, offline shell.
- Two layout shells over the same screens, as defined in the design system:
  - `< 1024px`: the mobile app layout (bottom tab bar, pinned CTA bar).
  - `≥ 1024px`: desktop layout (left sidebar, right rail on the trail, centered focus column on questions).
- Styling: the design system's CSS tokens and component CSS, ported into `packages/ui-web` (TypeScript, typed props from the existing `.d.ts` files).
- Product UI supports English (`en`) and Brazilian Portuguese (`pt-BR`). English is the source and fallback locale.
- All user-facing interface copy uses translation keys and locale message catalogs; do not hard-code copy in components.
- The initial locale follows the browser or device preference when supported, users can switch languages manually, and their choice is persisted locally. Once authenticated profile preferences exist, the selected locale is also synced to the user profile.
- Localization applies to product UI and navigation. Certification and learning content may remain in its source language until content localization is specified separately.
- Both locales follow the design system's voice rules.

### 5.2 Native app (`apps/mobile`, phase 4)

Pending [ADR-0007](adr/0007-mobile-app-expo-vs-capacitor.md): Expo (React Native) vs Capacitor (web app wrapped in a native shell). Either way it consumes `contracts`, `core` and `tokens`, and reuses the same English and Brazilian Portuguese message catalogs as the web app. Store requirements we already know about: Sign in with Apple (because we offer Google/GitHub login), in-app account deletion, privacy policy, stable versioned API.

### 5.3 Design system

The versioned source of truth lives in `packages/tokens` and `packages/ui-web`. Non-negotiables carried into code: 2px ink borders on everything tappable, one accent (Blue 500 `#2D5BFF`), Bricolage Grotesque 800 at 75% width in caps for headlines, lab/science voice, no emoji, no cloud-vendor logos.

---

## 6. Environments and infrastructure

See [ADR-0006](adr/0006-infrastructure-aws-terraform.md).

| | Stage | Prod |
|---|---|---|
| Purpose | Everything new lands here first; Zé studies on it from his phone | Real users; introduced in phase 3 |
| Web | S3 + CloudFront | S3 + CloudFront |
| API | Lambda + API Gateway HTTP API | Decided in phase 3 (Lambda, EC2 or Fargate) |
| Database | Neon free tier | RDS PostgreSQL, single-AZ, small Graviton instance |
| Secrets | SSM Parameter Store (standard, free) | SSM Parameter Store |
| Cost target | ~$0/month | As low as reasonable; every addition justified |

- **Terraform** for everything in AWS. Remote state in S3 with native lock file. Reusable modules in `infra/modules`, one root per environment in `infra/envs/{stage,prod}`.
- **CI deploys** through GitHub Actions using **OIDC** to assume an AWS role — no long-lived AWS keys anywhere.
- **AWS Budgets** alerts from day one.
- Known cost traps we avoid: NAT Gateway, ALB, unnecessary public IPv4 addresses, Multi-AZ databases, Secrets Manager where Parameter Store suffices.

Open: the project domain name (needed for `app.` / `api.` subdomains and cookies).

---

## 7. Quality and guardrails

Because most code will be written by AI agents, these are requirements from phase 1, not polish for later. See [ADR-0008](adr/0008-ai-first-guardrails.md).

**Local (before a commit leaves the machine)** — lefthook:
- pre-commit: format + lint on staged files, secret scan (gitleaks).
- commit-msg: Conventional Commits (commitlint).
- pre-push: typecheck + unit tests for affected packages.

**CI (every pull request)** — GitHub Actions, required to pass before merge:
- install with frozen lockfile, lint, typecheck, unit + integration tests, build;
- database migration check (migrations apply cleanly on a fresh database);
- secret scan, dependency audit;
- later: E2E (Playwright), coverage thresholds, AI code review agents.

**Repository rules:**
- `main` is protected: PR required, CI required, no force pushes, linear history.
- Every PR links its Linear ticket; the PR template asks what was tested and what risk it carries.
- Dependency updates via Renovate (or Dependabot).
- `CLAUDE.md` / `AGENTS.md` at the root and in each app tell agents the conventions, commands and boundaries.

**Code conventions:** TypeScript strict everywhere, ESLint with type-aware rules (e.g. no floating promises), Prettier, no `any` without a comment explaining why. Code, identifiers and commit messages in English.

---

## 8. Security baseline

From phase 1:
- HTTPS only; secure, `HttpOnly`, `SameSite` cookies for the web session; bearer tokens for the native app.
- Passwords handled by Better Auth (hashing, reset tokens); rate limiting on auth endpoints (brute force).
- All input validated with zod at the API edge, including size and complexity bounds; parameterized SQL via Drizzle only. Dynamic raw SQL must never contain user-controlled fragments.
- Authorization is enforced server-side for every resource and action; identifiers supplied by a client never establish ownership. Tests cover cross-user access and mass-assignment boundaries.
- React escapes text by default. Rendering raw HTML is prohibited unless a reviewed feature requires it and sanitizes it; rendered Markdown or code must not permit active content. A restrictive Content Security Policy and the other relevant browser security headers are set at CloudFront.
- CORS is restricted to known origins. Cookie-authenticated mutations have explicit CSRF protection appropriate to the chosen auth flow; `SameSite` is defense in depth, not the only control.
- Authentication and public endpoints have route-specific rate limits. Request-body limits, timeouts and bounded work per request prevent inexpensive malicious inputs from creating unbounded database or compute work.
- Least-privilege IAM per Lambda / service; secrets only in Parameter Store, never in the repo or in CI logs.
- Logs and telemetry exclude passwords, tokens, full authorization headers, submitted answers where unnecessary and other personal data not required for an operational purpose.
- Account deletion actually deletes or irreversibly anonymizes personal data according to the documented lifecycle, subject only to explicit and narrowly justified retention exceptions.

Before public production and hardened again in phase 5:
- Maintain a lightweight threat model covering trust boundaries and OWASP web/API risks, especially broken object authorization, auth/recovery abuse, XSS/script injection, SQL injection, CSRF and SSRF if outbound fetching is introduced.
- Use API Gateway/CloudFront protections, per-user and per-IP rate and concurrency limits, payload/time bounds, cost alarms and runbooks to mitigate abuse and DDoS. Record the WAF threat/cost decision before public production, enable it when warranted, and revisit the decision as exposure changes. These controls reduce impact; they do not claim to make DDoS impossible.
- Run dependency, secret and container scanning, and penetration-style reviews of authentication, account recovery, authorization and deletion flows.
- Native credentials use platform secure storage and never general-purpose app storage.

Prompt injection is not an MVP runtime attack surface because the MVP does not send user-controlled content to an LLM. It becomes a release gate for every AI feature: user and retrieved content are untrusted data, cannot override system policy, and cannot directly authorize tools or data access. AI services use least-privilege identities, scoped retrieval, output encoding, data-loss and cost controls, audit logs, and adversarial evaluations for prompt injection, retrieval poisoning, sensitive-data disclosure, unsafe rendering and tool abuse.

---

## 9. Data privacy and lifecycle

Privacy is an engineering constraint from the first stored account, not store-submission paperwork. The exact LGPD legal bases, retention durations, controller details, vendor terms and cross-border transfer safeguards require a documented product/legal decision before public launch; implementation tickets must not invent them.

From phase 1:
- Keep a versioned inventory of personal data collected by auth, profiles, learning events, logs, cookies and third-party SDKs. For each class record its purpose, sensitivity, access, system of record, recipients, proposed legal basis, retention rule and deletion behavior.
- Apply data minimization and purpose limitation. A future analytics or AI use does not by itself justify indefinite retention of raw learning history.
- Maintain a retention schedule implemented through database expiry, scheduled deletion or irreversible anonymization jobs as appropriate. It covers short-lived sessions and reset tokens, learning events such as `answer_attempt`, logs, caches, exports and backup expiration; "keep forever" requires an explicit justification.
- Account deletion covers primary and derived records and prevents orphaned identifiers from re-identifying a person. Copies in immutable backups expire within the documented window and are not silently restored as active user data.
- Start with strictly necessary cookies/storage only. Non-essential analytics, advertising or tracking SDKs require an updated inventory and, where applicable, prior consent that is recorded, withdrawable and honored before loading. A banner is not added when there is nothing optional to consent to.
- Privacy notices and consent surfaces use the same supported locales as the product and remain accessible from sign-up and settings.

Before public production and native store submission:
- Public policy text, in-product behavior, vendor contracts, store privacy labels/data-safety forms and the data inventory must agree.
- A verified process handles applicable data-subject rights without disclosing data to an impostor, and records the request and outcome without duplicating the requested personal data in logs.
- Hosting, authentication, email, observability, push and analytics providers are recorded as processors or recipients as applicable, including where data is processed and the approved transfer safeguard.
- The incident-response playbook includes personal-data breach assessment, evidence preservation, responsible owners and the decision path for regulator and affected-person notifications.
- Automated retention and deletion jobs, backup expiry and the complete account-deletion path are tested before launch and periodically thereafter.

---

## 10. Observability

- Phase 1: structured JSON logs (pino) with request id, user id (when known), route, latency and status; CloudWatch Logs with short retention in stage to keep cost down; uncaught errors alarmed.
- Phase 5: OpenTelemetry traces and metrics, dashboards (latency, error rate, sign-ups, lab completions), alerting, frontend error tracking.

---

## 11. Learning engine

MVP (phase 2), deterministic rules:
- A wrong answer re-queues the question at the end of the current lab.
- Every miss creates or updates a `review_item` in the Errata; the user can run a Retest of missed questions.
- XP per correct answer and per completed lab; daily streak by the user's timezone.

Post-MVP:
- **Spaced repetition with FSRS** — schedule each question per user based on their history in `answer_attempt`; questions you keep missing come back more often.
- **Adaptive learning** — weak chapters surface first; difficulty adjusts to performance.

---

## 12. AI in the product (post-MVP)

Kept out of the MVP on purpose, but the MVP prepares for it (answer event log, versioned questions, explanation per question, Postgres that can run `pgvector`).

- **"Why did I get this wrong?" chat** — the user opens a conversation about a specific mistake; the AI sees the question, the user's answer, the official explanation and the user's history, and grounds its answers through RAG over curated reference material.
- **Dynamic questions** — generate variations of concepts the user struggles with, always reviewed or validated before being served.
- **Content pipeline** — AI-assisted authoring of new questions and labs with human review.

These will likely run as a separate service with its own rate limits and cost controls; that decision gets its own ADR when we get there. That ADR must also define the allowed data flows, retention, human oversight and the prompt-injection and data-exfiltration controls required by sections 8 and 9.

---

## 13. Decision index

| ADR | Decision | Status |
|---|---|---|
| [0001](adr/0001-record-architecture-decisions.md) | Record architecture decisions as ADRs | Accepted |
| [0002](adr/0002-monorepo.md) | One monorepo with three apps | Accepted |
| [0003](adr/0003-backend-typescript-hono.md) | Backend in TypeScript with Hono, runtime-agnostic | Accepted |
| [0004](adr/0004-web-vite-react-spa.md) | Web as a Vite + React SPA, not Next.js | Accepted |
| [0005](adr/0005-auth-better-auth.md) | Authentication with Better Auth | Accepted |
| [0006](adr/0006-infrastructure-aws-terraform.md) | AWS + Terraform, stage on free tiers | Accepted |
| [0007](adr/0007-mobile-app-expo-vs-capacitor.md) | Native app: Expo vs Capacitor | Proposed |
| [0008](adr/0008-ai-first-guardrails.md) | Guardrails from day one for AI-written code | Accepted |
| [0009](adr/0009-content-as-code-and-answer-events.md) | Questions as code; answers as an event log | Accepted |

## 14. Open questions

- Domain name.
- Production API runtime (Lambda vs EC2 vs Fargate) — phase 3.
- Expo vs Capacitor — phase 4, after a spike.
- How many labs unlock mascot levels 2–4 (from the design system's open items).
- Source and licensing of reference material for the future RAG.
- LGPD legal bases and retention durations per data class, controller/privacy contact details, processor terms and any cross-border transfer safeguards; all must be resolved before public production.
