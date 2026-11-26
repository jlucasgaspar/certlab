import { describe, expect, it } from 'vitest';

import { workspaceName } from '../src/index';

describe('@certlab/contracts', () => {
  it('exposes its workspace name', () => {
    expect(workspaceName).toBe('@certlab/contracts');
  });
});
