# Architecture Decision Records

Each significant decision gets a short, numbered record: what we decided, why, and what it costs us. ADRs are immutable once accepted — to change a decision, write a new ADR that supersedes the old one and update the old one's status.

They also serve as raw material for dev.to / LinkedIn articles.

## Format

File name: `NNNN-short-title.md`. Sections: **Status** (Proposed · Accepted · Superseded by NNNN · Deprecated), **Date**, **Context**, **Decision**, **Consequences**, **Alternatives considered**.

Copy [`template.md`](template.md) to start a new one.

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-monorepo.md) | One monorepo with three apps | Accepted |
| [0003](0003-backend-typescript-hono.md) | Backend in TypeScript with Hono, runtime-agnostic | Accepted |
| [0004](0004-web-vite-react-spa.md) | Web as a Vite + React SPA | Accepted |
| [0005](0005-auth-better-auth.md) | Authentication with Better Auth | Accepted |
| [0006](0006-infrastructure-aws-terraform.md) | AWS + Terraform, stage on free tiers | Accepted |
| [0007](0007-mobile-app-expo-vs-capacitor.md) | Native app: Expo vs Capacitor | Proposed |
| [0008](0008-ai-first-guardrails.md) | Guardrails from day one for AI-written code | Accepted |
| [0009](0009-content-as-code-and-answer-events.md) | Questions as code; answers as an event log | Accepted |
