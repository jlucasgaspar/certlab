# Certlab — MVP Roadmap

> Status: draft · Last updated: 2026-11-27
> Architecture: [design.md](design.md) · Decisions: [adr/](adr/README.md)

Five phases. Everything lands in **stage** first, built the cheapest way that is still done properly. Production comes only after the product is real and used daily (by Zé, studying CLF-C02 on his phone).

Each phase ends with an **exit check**: what must be true before moving on.

This roadmap is the spec source; the actual work is tracked as tickets in **Linear** (created from this file by an AI agent). Checkboxes are not updated per implementation ticket. The final wrap-up issue for each phase or numbered workstream reconciles them against what was actually delivered, records deferrals and updates the supporting documentation.

---

## Phase 1 — Foundation, auth and the deploy pipeline (stage)

Goal: a repository where AI agents can safely open PRs, and a login that works on a real URL.

**1.1 Repository foundation** (before the first AI-written PR)
- [x] Git repo + GitHub, `main` protected (PR + green CI required, no force push).
- [x] pnpm workspaces + Turborepo; `apps/api`, `apps/web`, `packages/{contracts,core,tokens,config}`.
- [x] TypeScript strict, ESLint (type-aware) + Prettier, Vitest.
- [x] lefthook: format/lint + gitleaks on commit, commitlint on message, typecheck + tests on push.
- [x] GitHub Actions CI: lint, typecheck, test, build, secret scan, dependency audit.
- [x] `CLAUDE.md` / `AGENTS.md`, PR template, issue template.
- [x] Move the current root `README.md` (product vision) to `docs/vision.md`.
- [x] Write a new root `README.md` for developers: what Certlab is (one paragraph + link to `docs/vision.md`), repo layout, prerequisites, setup, common commands, environments, links to `docs/design.md`, `docs/roadmap.md` and `docs/adr/`.
- [x] Renovate (weekly, grouped, no automerge). Dependabot security updates are also enabled for advisories.
- [x] Discord webhook notifications when a pull request is opened and when one is merged into `main`; keep the webhook URL in a GitHub secret, never in the repository.
- [x] Repository hardening: Code Owner review on `main`, access and Actions least privilege, secrets inventory, `SECURITY.md` and GitHub security features, documented in `docs/repository-security.md`.
  - Delivered: `CODEOWNERS`, `SECURITY.md`, Code Owner approval rule, Actions least privilege, secrets inventory and Security features. The maintainer confirmed on 2026-11-27 that the installed GitHub Apps and the Discord webhook are in order. Known deviation: the repository admin role bypasses the approval rule so the sole maintainer can merge. Remove the bypass when a second reviewer exists (not a priority; see `docs/repository-security.md`).
- Dropped: the shared `docs/backlog.md` handoff between implementation agents and the PM agent. The maintainer decided not to build it (2026-11-27), so deferred findings are reported in the pull request instead.
- [x] Phase 1.1 wrap-up: reconcile delivered work and roadmap checkboxes, update documentation and agent guidance, verify versions and quality gates, and record follow-up work.

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

**1.5 Data protection and privacy baseline**
- [ ] Inventory the personal data collected by auth, profiles, learning events, logs and support; classify sensitivity, purpose, access and the proposed LGPD legal basis without collecting data that has no defined purpose.
- [ ] Define a retention schedule for each data class, including sessions and reset tokens, `answer_attempt`, operational logs and backups; implement automated expiry, deletion or anonymization where the duration is known, and track unresolved durations as a launch-blocking legal/product decision.
- [ ] Define account-deletion behavior across primary, derived and cached data, including the bounded expiry of copies retained in backups and any narrowly justified legal or security exception.
- [ ] Maintain a cookie and SDK inventory. Start with strictly necessary authentication and preference storage only; do not add analytics, advertising or other non-essential tracking until it is documented and, when required, blocked behind consent with a way to withdraw it.
- [ ] Publish a concise stage privacy notice in English and Brazilian Portuguese before anyone beyond the maintainer is invited to create an account; link it from sign-up and settings.

**1.6 Web UI (local, then stage)**
- [ ] Vite + React app, design tokens and fonts, base components ported from the design system.
- [ ] Localization foundation: English (`en`) and Brazilian Portuguese (`pt-BR`) message catalogs, English fallback, browser locale detection, manual language selection and persisted preference; no hard-coded user-facing copy.
- [ ] Screens in both supported locales: Welcome, Sign up / Log in, Reset password, empty "bench" after login.
- [ ] Deploy to S3 + CloudFront (stage) via CI.

**1.7 AI workflow**
- [ ] Linear workspace and project; ticket template following the [issue writing standard](issue-writing-standard.md).
- [ ] First loop: AI writes ticket → AI opens PR → CI → human review → merge → auto-deploy to stage.

**Exit check:** from a phone, on the stage URL, you can sign up, log in, reset your password and delete your account; the stage data inventory, retention rules and privacy notice match that behavior; every change reached stage through a reviewed PR with green CI.

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
- [ ] Pre-launch threat model and security review covering authorization, auth/recovery, XSS/script injection, SQL injection, CSRF, malicious payloads and abuse; remediate launch-critical findings before public traffic.
- [ ] Edge and DDoS/abuse baseline: CloudFront/API Gateway protections, route-specific throttling, payload and timeout bounds, concurrency/cost alarms and a documented WAF decision; enable WAF before public launch when the threat/cost assessment requires it.
- [ ] API versioning policy (`/v1`) frozen before phase 4.
- [ ] Sign in with Apple added to auth.
- [ ] Final privacy policy and terms in the supported product locales, linked from the web app and usable as stable public URLs for both stores; the policy must match the implemented data flows and identify the controller and privacy contact.
- [ ] LGPD operating procedure for access, correction, deletion, consent withdrawal and other applicable data-subject requests, with request verification and an auditable response record that does not expose the requested data.
- [ ] Production data-retention enforcement: scheduled expiry/deletion/anonymization jobs, log retention, backup expiration and a tested account-deletion path across primary and derived data.
- [ ] Processor and data-transfer register for hosting, authentication, email, observability, push and any analytics vendors; required contracts and unresolved legal bases or transfer safeguards block public launch.
- [ ] Cookie/SDK inventory reconciled with production. If non-essential tracking exists, consent is opt-in where required, recorded, revocable and honored before those technologies load; otherwise no cookie banner is added merely for strictly necessary storage.
- [ ] Incident-response and personal-data-breach playbook with owners, evidence preservation, severity assessment and applicable notification decision points.

**Exit check:** prod serves the web app; a restore from backup and the personal-data deletion/retention paths have been tested; the public privacy disclosures match production and no unresolved launch-blocking privacy decision remains; monthly cost is known and within budget.

---

## Phase 4 — Native app and store submission

- [ ] Spike: Expo vs Capacitor (trail screen + a drag-based question on iPhone and a low-end Android) → close ADR-0007.
- [ ] Toolchain: Xcode, Android Studio, Apple Developer and Google Play accounts.
- [ ] `apps/mobile` consuming `contracts`, `core`, `tokens`.
- [ ] Native UI consuming the shared English and Brazilian Portuguese message catalogs and honoring the user's saved language preference.
- [ ] Native essentials: Sign in with Apple, push notifications (streak reminders), haptics, deep links.
- [ ] Store assets (icon 1024 exported crisp, screenshots, descriptions) and store privacy/data-safety disclosures reconciled against the production data inventory, SDKs, retention and account-deletion behavior.
- [ ] Pre-submission privacy review: policy URLs work without authentication, in-app disclosures and permissions are contextual, consent/withdrawal works where applicable, and Apple/Google declarations match actual behavior.
- [ ] TestFlight / internal testing track, then submission.

**Exit check:** the app is approved (or in review) on both stores, talking to prod, with store disclosures that match the shipped build and backend.

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
- [ ] Security verification: update the threat model and test authorization boundaries, auth and account recovery, XSS/script injection, SQL injection, CSRF, SSRF where outbound requests exist, malicious payloads, dependency/secret exposure and abuse/DDoS controls; remediate launch-critical findings.
- [ ] Edge and abuse hardening: verify and tune WAF or the documented alternative, per-user/per-IP rate and concurrency limits, request-size and timeout bounds, cost alarms and a degradation/runbook strategy for traffic floods.
- [ ] Privacy verification: reconcile the data map, processor register, public notices and store declarations with the deployed system; test data-subject request handling, account deletion, retention jobs and backup expiry.
- [ ] AI security gate (when an AI feature is introduced): threat-model prompt injection, retrieval poisoning, sensitive-data disclosure, unsafe output rendering and tool abuse; treat user/retrieved content as untrusted, enforce least privilege and cost limits, and run adversarial evaluations before release.

**Future (post-MVP backlog)**
- [ ] Spaced repetition with FSRS: questions you miss often come back more often, mastered ones less.
- [ ] Adaptive learning: weak chapters first, difficulty tuned to performance, lab recommendations.
- [ ] AI tutor chat: after a mistake, go beyond the standard explanation and discuss *your* error with an AI grounded by RAG.
- [ ] Dynamic questions generated around concepts you struggle with (validated before serving).
- [ ] AI-assisted content pipeline for new exams (Google Cloud, Azure, then AI and developer tools).
- [ ] dev.to / LinkedIn articles from the ADRs and `docs/articles/` drafts.

**Exit check:** a written plan for v1 after the MVP, with priorities.
