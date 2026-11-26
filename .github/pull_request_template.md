## Summary

<!-- What changes and why, in a few bullets. -->

Linear: <!-- Issue identifier, for example LAB-123. Required. -->

## Testing

<!-- What you ran and what you verified. Mention anything you did not test. -->

- [ ] `pnpm format:check`, `pnpm lint`, `pnpm typecheck`, `pnpm test` and `pnpm build` pass
- [ ] `pnpm lint:commits` passes (every commit follows Conventional Commits)

## Risk

<!-- What could break, who is affected, and how to roll back. -->

## Checklist

- [ ] The change is scoped to the Linear issue above; unrelated findings are reported separately
- [ ] No lint rule, test, type check or CI gate was weakened to make this pass
- [ ] No secrets, personal paths or private identifiers were added
- [ ] User-facing copy uses translation keys (`en` and `pt-BR`)
