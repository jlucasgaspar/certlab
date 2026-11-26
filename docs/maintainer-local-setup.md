# Maintainer Local Setup

This repository is public. Private services and machine-specific agent behavior must remain outside version control so a clean clone works without access to a maintainer's accounts.

## Public and local boundaries

Commit project-wide conventions, architecture, validation commands, and portable tooling. Keep private issue-tracker connections, OAuth state, personal filesystem paths, and client-specific permissions local.

The following files are intentionally ignored:

- `.mcp.json`: local MCP connections used by Claude Code.
- `.codex/config.toml`: local Codex MCP and maintainer instructions.
- `CLAUDE.local.md`: private project-specific instructions for Claude Code.
- `.claude/settings.local.json`: local Claude Code permissions and hooks.
- `.claude/hooks-local/`: local enforcement scripts.
- `.agent-local/`: local helper executables shared by agent clients.

OAuth credentials are stored by each client outside the repository. Never place access tokens or authorization headers in these files.

## Shared agent instructions

`AGENTS.md` is the canonical public instruction file. `CLAUDE.md` imports it so Codex, Claude Code, and other compatible agents receive the same project-wide guidance without relying on filesystem symlinks.

Use local instruction files only for details that do not apply to an unaffiliated contributor, such as private team identifiers or maintainer-specific permissions.

## Verification

Run the repository hygiene check before committing agent or maintainer configuration:

```sh
scripts/check-public-repo-hygiene.sh
```

Confirm ignored local files are not tracked:

```sh
git check-ignore .mcp.json .codex/config.toml CLAUDE.local.md .claude/settings.local.json
git ls-files .mcp.json .codex/config.toml CLAUDE.local.md .claude/settings.local.json
```

The first command should list the local files. The second command should print nothing.

On a new machine, recreate the ignored configuration locally and complete each client's OAuth flow. Do not copy credential stores into the repository.

## Discord MCP

The Discord MCP used by maintainers is a community integration, not an official Discord product. Pin its version, restrict it to an explicit guild allow-list, expose only the required toolsets, and start in read-only mode. Grant the Discord bot access only to the channels it needs.

Store the bot token in the operating system credential store, never in `.mcp.json`, shell history, `.env` files, or repository content. Local MCP configuration may call an ignored helper from `.agent-local/` that retrieves the token at runtime. Keep server and channel identifiers in ignored local instructions when they are not intended to be public.
