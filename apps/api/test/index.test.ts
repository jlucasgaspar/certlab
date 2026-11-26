import { describe, expect, it } from 'vitest';

import { workspaceName } from '../src/index';

describe('@certlab/api', () => {
  it('exposes its workspace name', () => {
    expect(workspaceName).toBe('@certlab/api');
  });
});
