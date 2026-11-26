import { describe, expect, it } from 'vitest';

import { workspaceName } from '../src/index';

describe('@certlab/web', () => {
  it('exposes its workspace name', () => {
    expect(workspaceName).toBe('@certlab/web');
  });
});
