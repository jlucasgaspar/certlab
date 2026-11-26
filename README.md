# Certlab

Certlab is a gamified, mobile-first learning platform for technical certifications: "Duolingo for certs". Users learn through short interactive exercises, mistakes come back for review, and progress is visible through XP and daily streaks. The first exam built end to end is AWS Certified Cloud Practitioner (CLF-C02). The product vision lives in [docs/vision.md](docs/vision.md).

> **Status:** early foundation phase. The repository structure, toolchain and CI are in place; product features are not implemented yet. Follow the delivery plan in [docs/roadmap.md](docs/roadmap.md).

## Repository layout

```text
certlab/
├── apps/
│   ├── api/          Hono API (placeholder)
│   └── web/          Vite + React SPA (placeholder)
├── packages/
│   ├── contracts/    zod schemas shared by API and clients
│   ├── core/         pure domain logic shared by clients
│   ├── tokens/       design tokens
│   └── config/       shared TypeScript, ESLint, Prettier and Vitest presets
├── docs/             design, roadmap, ADRs and contributor guides
└── scripts/          repository scripts
```

`apps/mobile`, `packages/{ui-web,i18n}`, `content/` and `infra/` are planned for later roadmap phases. Apps may depend on packages; packages never depend on apps. See [docs/design.md](docs/design.md) and [ADR-0002](docs/adr/0002-monorepo.md).

## Prerequisites

- **Node.js 26** (see `.nvmrc`).
- **pnpm**, in the version pinned by the `packageManager` field of `package.json`. See the [pnpm installation guide](https://pnpm.io/installation).
- **gitleaks** on your `PATH`, used by the pre-commit secret scan. On macOS: `brew install gitleaks`. See [docs/git-hooks.md](docs/git-hooks.md).

## Setup

```sh
pnpm install --frozen-lockfile
```

This installs dependencies and registers the local Git hooks.

## Common commands

Run all commands from the repository root. Turborepo runs each task in every workspace that defines it.

| Command                          | What it does                                                    |
| -------------------------------- | --------------------------------------------------------------- |
| `pnpm lint`                      | ESLint with type-aware rules                                    |
| `pnpm typecheck`                 | TypeScript in strict mode                                       |
| `pnpm test`                      | Vitest                                                          |
| `pnpm build`                     | Build every workspace                                           |
| `pnpm format` / `format:check`   | Write or check Prettier formatting                              |
| `pnpm lint:commits`              | Validate every commit of your branch against `main`             |
| `pnpm typecheck:affected`        | Typecheck only workspaces affected by your changes              |
| `pnpm test:affected`             | Test only workspaces affected by your changes                   |
| `pnpm test:hooks`                | Check that the commit message and secret-scan hooks work        |
| `pnpm workspaces`                | List the workspaces                                             |
| `scripts/check-public-repo-hygiene.sh` | Check for private files and personal paths in tracked files |

Before opening a pull request, run `pnpm format:check`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build` and `pnpm lint:commits`.

## Environments

There are no deployed environments yet. Everything runs locally for now. A **stage** environment (AWS, with Neon PostgreSQL) comes in phase 1, and **production** in phase 3. See [docs/roadmap.md](docs/roadmap.md) and [ADR-0006](docs/adr/0006-infrastructure-aws-terraform.md).

## Contributing

- Branches are named `lab-<number>-<short-description>`, commits follow [Conventional Commits](https://www.conventionalcommits.org/), and pull requests link their issue and are merged with a merge commit.
- Local Git hooks give fast feedback; CI is the gate. `main` is protected and requires a pull request with all checks green. See [docs/git-hooks.md](docs/git-hooks.md) and [docs/ci.md](docs/ci.md).
- Coding agents and humans follow [AGENTS.md](AGENTS.md). Repository documentation and code are written in English, and the product interface supports English and Brazilian Portuguese.

## Documentation

| Document                                                       | Purpose                                              |
| -------------------------------------------------------------- | ---------------------------------------------------- |
| [docs/vision.md](docs/vision.md)                               | Product vision and research backlog                  |
| [docs/design.md](docs/design.md)                               | System design and architecture                       |
| [docs/roadmap.md](docs/roadmap.md)                             | Delivery plan by phase                               |
| [docs/adr/](docs/adr/README.md)                                | Architecture decision records                        |
| [docs/git-hooks.md](docs/git-hooks.md)                         | Local hooks and commit conventions                   |
| [docs/ci.md](docs/ci.md)                                       | CI checks and branch protection                      |
| [docs/issue-writing-standard.md](docs/issue-writing-standard.md) | How to write implementation issues                 |
| [docs/maintainer-local-setup.md](docs/maintainer-local-setup.md) | Public and local configuration boundaries          |
