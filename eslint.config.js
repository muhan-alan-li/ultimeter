import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';

export default tseslint.config(
    { ignores: ['dist/**', 'node_modules/**'] },
    js.configs.recommended,
    ...tseslint.configs.recommended,
    { languageOptions: { globals: { ...globals.browser, ...globals.node } } },
    {
        files: ['src/domain/**/*.ts'],
        rules: { 'no-restricted-imports': ['error', { patterns: ['react', 'react-dom', 'react-dom/*', 'dexie', '**/storage', '**/storage/**', '**/app/**', '**/controllers/**', '**/views/**'] }] },
    },
    {
        files: ['src/controllers/**/*.ts'],
        rules: { 'no-restricted-imports': ['error', { patterns: ['react', 'react-dom', 'react-dom/*', 'dexie', '**/storage/SessionRepository', '**/storage/queries', '**/views/**', '**/app/context', '**/app/useController'] }] },
    },
    {
        files: ['src/views/**/*.tsx'],
        rules: { 'no-restricted-imports': ['error', { patterns: ['dexie', '**/storage', '**/storage/**'] }] },
    },
    {
        files: ['src/app/**/*.{ts,tsx}'],
        rules: { 'no-restricted-imports': ['error', { patterns: ['dexie', '**/storage/SessionRepository'] }] },
    },
);
