# 0004. Web as a Vite + React SPA

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

The web app covers desktop and mobile web (PWA). Almost all of it sits behind login; SEO matters only for a future marketing landing page. The design system is already React + CSS. Hosting must be near-free.

## Decision

- **Vite + React + TypeScript**, TanStack Router (type-safe routes), TanStack Query (server state).
- Built as static files, served from **S3 + CloudFront**.
- PWA (installable, offline shell).
- The marketing landing page, when needed, is a separate static site (e.g. Astro) or prerendered pages — decided then.

## Consequences

- Hosting cost is pennies; no server to run or patch for the web.
- No server rendering: first paint depends on the JS bundle, so we keep bundles small and split by route.
- Auth uses cookies against `api.<domain>`; CORS and cookie settings must be right from the start.

## Alternatives considered

- **Next.js** — strong for SEO-heavy and server-rendered sites, but adds a server runtime (OpenNext or containers on AWS), React Server Components complexity and cost, for an app that is almost entirely authenticated.
- **Remix / React Router framework mode** — same server-runtime trade-off.
