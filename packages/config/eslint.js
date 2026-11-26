import js from '@eslint/js';
import { defineConfig } from 'eslint/config';
import prettier from 'eslint-config-prettier';
import globals from 'globals';
import tseslint from 'typescript-eslint';

/**
 * Shared ESLint flat config with type-aware rules.
 *
 * @param {string} tsconfigRootDir Directory of the workspace tsconfig.json.
 */
export function createConfig(tsconfigRootDir) {
  return defineConfig(
    { ignores: ['dist/**', 'coverage/**', '.turbo/**'] },
    js.configs.recommended,
    tseslint.configs.strictTypeChecked,
    tseslint.configs.stylisticTypeChecked,
    {
      languageOptions: {
        globals: globals.node,
        parserOptions: {
          projectService: true,
          tsconfigRootDir,
        },
      },
    },
    prettier,
  );
}
