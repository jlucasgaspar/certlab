import { describe, expect, it } from 'vitest';

import { createConfig } from '../eslint/index.js';
import base from '../tsconfig/base.json' with { type: 'json' };

describe('shared presets', () => {
  it('keeps TypeScript strict mode enabled', () => {
    expect(base.compilerOptions.strict).toBe(true);
    expect(base.compilerOptions.noUncheckedIndexedAccess).toBe(true);
    expect(base.compilerOptions.exactOptionalPropertyTypes).toBe(true);
  });

  it('keeps type-aware linting enabled', () => {
    const config = createConfig('/tmp');
    const parserOptions = config.flatMap((entry) => entry.languageOptions?.parserOptions ?? []);
    expect(parserOptions).toContainEqual(expect.objectContaining({ projectService: true }));
  });
});
