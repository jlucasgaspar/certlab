import { describe, expect, it } from 'vitest';

import { workspaceName } from '../src/index';

describe('@certlab/tokens', () => {
  it('exposes its workspace name', () => {
    expect(workspaceName).toBe('@certlab/tokens');
  });
});
