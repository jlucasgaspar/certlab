# 0005. Authentication with Better Auth

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

The design calls for email + password (with reset), Google and GitHub sign-in. Publishing in the App Store adds Sign in with Apple (required when third-party logins are offered) and in-app account deletion. The web uses cookies; the native app will need token-based sessions. We want user data in our own database and no per-user pricing.

## Decision

Use **Better Auth**, self-hosted inside `apps/api`, storing users, accounts and sessions in our PostgreSQL through Drizzle.

- Phase 1: email + password, password reset, Google, GitHub, account deletion, rate limiting on auth routes.
- Phase 3 (before the store submission): Sign in with Apple.
- Phase 4: native app sessions via Better Auth's mobile support (bearer tokens / secure storage).

## Consequences

- No vendor cost per user; user data stays in our database.
- We own the operational side: email delivery for resets (e.g. Amazon SES), OAuth app configuration per environment, security updates of the library.
- Auth UI is ours, so it follows the design system exactly.

## Alternatives considered

- **Supabase Auth** — managed and convenient, but couples us to Supabase and its hosting model.
- **Clerk** — polished, but per-user pricing grows with the product and its prebuilt UI does not follow our design system.
- **Hand-rolled auth** — maximum learning, maximum security risk; not worth it for a product whose value is elsewhere.
