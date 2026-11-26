# Certlab — MVP Roadmap

> Status: draft · Last updated: 2026-11-26
> Architecture: [design.md](design.md) · Decisions: [adr/](adr/README.md)

Five phases. Everything lands in **stage** first, built the cheapest way that is still done properly. Production comes only after the product is real and used daily (by Zé, studying CLF-C02 on his phone).

Each phase ends with an **exit check**: what must be true before moving on.

This roadmap is the spec source; the actual work is tracked as tickets in **Linear** (created from this file by an AI agent). Checkboxes here are not updated per ticket.

---

## Phase 1 — Foundation, auth and the deploy pipeline (stage)

Goal: a repository where AI agents can safely open PRs, and a login that works on a real URL.

**1.1 Repository foundation** (before the first AI-written PR)
- [ ] Git repo + GitHub, `main` protected (PR + green CI required, no force push).
- [ ] pnpm workspaces + Turborepo; `apps/api`, `apps/web`, `packages/{contracts,core,tokens,config}`.
- [ ] TypeScript strict, ESLint (type-aware) + Prettier, Vitest.
- [ ] lefthook: format/lint + gitleaks on commit, commitlint on message, typecheck + tests on push.
- [ ] GitHub Actions CI: lint, typecheck, test, build, secret scan, dependency audit.
- [ ] `CLAUDE.md` / `AGENTS.md`, PR template, issue template.
- [ ] Move the current root `README.md` (product vision) to `docs/vision.md`.
- [ ] Write a new root `README.md` for developers: what Certlab is (one paragraph + link to `docs/vision.md`), repo layout, prerequisites, setup, common commands, environments, links to `docs/design.md`, `docs/roadmap.md` and `docs/adr/`.
- [ ] Renovate or Dependabot.

**1.2 Infrastructure bootstrap**
- [ ] AWS account hygiene: no root usage, MFA, AWS Budgets alerts.
- [ ] Terraform remote state (S3) and GitHub OIDC role for CI.
- [ ] Neon project for stage.

**1.3 Walking skeleton**
- [ ] API with `/health` (Hono) deployed to Lambda + HTTP API by CI.
- [ ] Structured logging (pino) with request id.

**1.4 Authentication (backend)**
- [ ] Better Auth: email + password, Google, GitHub; sessions; password reset; account deletion.
- [ ] Drizzle schema + SQL migrations; query-driven indexes only (each non-constraint index must serve a documented access pattern); migration step in CI/CD.
- [ ] Rate limiting on auth endpoints.

**1.5 Web UI (local, then stage)**
- [ ] Vite + React app, design tokens and fonts, base components ported from the design system.
- [ ] Localization foundation: English (`en`) and Brazilian Portuguese (`pt-BR`) message catalogs, English fallback, browser locale detection, manual language selection and persisted preference; no hard-coded user-facing copy.
- [ ] Screens in both supported locales: Welcome, Sign up / Log in, Reset password, empty "bench" after login.
- [ ] Deploy to S3 + CloudFront (stage) via CI.

**1.6 AI workflow**
- [ ] Linear workspace and project; ticket template following the [issue writing standard](issue-writing-standard.md).
- [ ] First loop: AI writes ticket → AI opens PR → CI → human review → merge → auto-deploy to stage.

**Exit check:** from a phone, on the stage URL, you can sign up, log in, reset your password and delete your account; every change reached stage through a reviewed PR with green CI.

---

## Phase 2 — The learning product (stage)

Goal: study CLF-C02 for real on your phone.

- [ ] Content: question schema per kind, `content/` folder, seed pipeline; CLF-C02 chapters and labs written (AI-assisted, human-reviewed, never copied from exam dumps).
- [ ] Exam picker (provider filter, levels).
- [ ] Lab trail (chapters, nodes, floating lab card, thesis defense node).
- [ ] Lab session: server-side answer validation, explanation after each answer, wrong answers re-queued at the end.
- [ ] Question kinds, in order: Multiple choice → Choose two → Sequence → Match pairs → Exam scenario → Complete the code → Diagram.
- [ ] `answer_attempt` event log recorded from the first answer.
- [ ] Errata + Retest (simple rules).
- [ ] XP, levels, daily streak (timezone-aware).
- [ ] Profile.
- [ ] Language preference in Profile, persisted locally and synced to the authenticated user profile.
- [ ] PWA: installable, app icon, offline shell.
- [ ] Desktop layout (sidebar, right rail) for the same screens.
- [ ] E2E smoke test of the core loop (log in → lab → answer → errata).

**Exit check:** you complete CLF-C02 labs daily on the stage PWA; Errata and streak behave correctly; no known data-loss bugs.

---

## Phase 3 — Production

Goal: everything built so far running in production, properly, at low cost. Comes before the native app because the stores review the app against a real backend, a shipped app cannot be hotfixed instantly, and store rules (account deletion, Sign in with Apple, privacy policy) depend on the backend.

- [ ] ADR: production API runtime (Lambda vs EC2 vs Fargate) and DB connectivity.
- [ ] Terraform `envs/prod`: RDS PostgreSQL, API, S3 + CloudFront, domain + TLS.
- [ ] Data migration path stage → prod (content only; stage users stay in stage).
- [ ] Backups and a tested restore.
- [ ] Alarms on errors, latency and cost.
- [ ] API versioning policy (`/v1`) frozen before phase 4.
- [ ] Sign in with Apple added to auth.
- [ ] Privacy policy and terms pages.

**Exit check:** prod serves the web app; a restore from backup has been tested; monthly cost is known and within budget.

---

## Phase 4 — Native app and store submission

- [ ] Spike: Expo vs Capacitor (trail screen + a drag-based question on iPhone and a low-end Android) → close ADR-0007.
- [ ] Toolchain: Xcode, Android Studio, Apple Developer and Google Play accounts.
- [ ] `apps/mobile` consuming `contracts`, `core`, `tokens`.
- [ ] Native UI consuming the shared English and Brazilian Portuguese message catalogs and honoring the user's saved language preference.
- [ ] Native essentials: Sign in with Apple, push notifications (streak reminders), haptics, deep links.
- [ ] Store assets (icon 1024 exported crisp, screenshots, descriptions), privacy labels.
- [ ] TestFlight / internal testing track, then submission.

**Exit check:** the app is approved (or in review) on both stores, talking to prod.

---

## Phase 5 — Review, hardening and what comes next

Goal: package the MVP, raise the quality bar, and plan the future.

**Review and decide**
- [ ] Walk through everything built; list gaps, debts and rough edges.
- [ ] Decide: launch publicly now, or what else must go in first.

**Hardening**
- [ ] Automated tests: coverage thresholds for API and web, E2E suite for the main journeys, contract tests between API and clients.
- [ ] CI: fully defined pipeline, AI code review agents (bugs, security, architecture), preview environments if cheap.
- [ ] Observability: OpenTelemetry traces and metrics, dashboards, alerting, frontend and mobile error tracking.
- [ ] Security: WAF, per-user/per-IP rate limits, OWASP review, dependency and secret scanning in place, auth flow review.

**Future (post-MVP backlog)**
- [ ] Spaced repetition with FSRS: questions you miss often come back more often, mastered ones less.
- [ ] Adaptive learning: weak chapters first, difficulty tuned to performance, lab recommendations.
- [ ] AI tutor chat: after a mistake, go beyond the standard explanation and discuss *your* error with an AI grounded by RAG.
- [ ] Dynamic questions generated around concepts you struggle with (validated before serving).
- [ ] AI-assisted content pipeline for new exams (Google Cloud, Azure, then AI and developer tools).
- [ ] dev.to / LinkedIn articles from the ADRs and `docs/articles/` drafts.

**Exit check:** a written plan for v1 after the MVP, with priorities.
