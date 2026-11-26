# 0009. Questions as code; answers as an event log

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

Certlab's value depends on the question bank (seven question kinds, per exam → chapter → lab) and, later, on adaptive learning and an AI tutor that need each user's full answer history. Questions will be authored with AI help and must be reviewed like code.

## Decision

**Content as code.**
- Questions, labs, chapters and exams live as versioned files in `content/` (YAML or JSON).
- Each question kind has a zod schema in `packages/contracts` (discriminated union on `kind`); CI validates every content file against it.
- A seed step loads content into PostgreSQL (`question.payload` / `question.answer` as JSONB). Each question carries a `version`; changing the correct answer bumps it.
- New content arrives through PRs, reviewed like any other change. Content is original — never copied from exam dumps.

**Answers as an append-only event log.**
- Every submitted answer is stored in `answer_attempt`: user, question id, question version, submitted answer, correct/incorrect, time spent, timestamp.
- Derived state (Errata items, XP, streak, future FSRS schedules) is computed from or alongside these events; events are never updated or deleted, except by account deletion.

## Consequences

- Content history, review and rollback come from git for free.
- Adaptive review (FSRS), analytics and the AI tutor can be built later on data collected since day one.
- The event table grows with usage; it needs proper indexes and, eventually, partitioning or archiving.

## Alternatives considered

- **Admin UI / CMS for content** — useful later for non-developers; premature now and harder to review.
- **Store only the latest result per question** — simpler, but throws away the history adaptive learning needs.
