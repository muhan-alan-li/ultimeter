import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import prettier from 'eslint-config-prettier/flat';
import stylistic from '@stylistic/eslint-plugin';

export default tseslint.config(
    { ignores: ['dist/**', 'node_modules/**'] },
    js.configs.recommended,
    ...tseslint.configs.recommended,
    {
        files: ['src/**/*.{ts,tsx}'],
        rules: {
            curly: ['error', 'all'],
            eqeqeq: ['error', 'always'],
            'no-var': 'error',
            'sort-imports': ['error', { ignoreCase: true, ignoreDeclarationSort: true }],
            '@typescript-eslint/consistent-type-imports': [
                'error',
                { prefer: 'type-imports', fixStyle: 'inline-type-imports' },
            ],
            '@typescript-eslint/no-import-type-side-effects': 'error',
            '@typescript-eslint/array-type': ['error', { default: 'array-simple' }],
            '@typescript-eslint/no-inferrable-types': 'error',
        },
    },
    {
        ...reactHooks.configs.flat.recommended,
        files: ['src/**/*.{ts,tsx}'],
        rules: {
            ...reactHooks.configs.flat.recommended.rules,
            'react-hooks/exhaustive-deps': 'error',
        },
    },
    { languageOptions: { globals: { ...globals.browser, ...globals.node } } },
    {
        files: ['src/domain/**/*.ts'],
        rules: {
            'no-restricted-imports': [
                'error',
                {
                    patterns: [
                        'react',
                        'react-dom',
                        'react-dom/*',
                        'dexie',
                        '**/storage',
                        '**/storage/**',
                        '**/app/**',
                        '**/controllers/**',
                        '**/views/**',
                    ],
                },
            ],
        },
    },
    {
        files: ['src/domain/**/*.ts'],
        rules: { '@typescript-eslint/consistent-type-definitions': ['error', 'interface'] },
    },
    {
        files: [
            'src/domain/{Session,Team,Player,Opponent,Tournament,Game,Point,PlayEvent,Halftime,types}.ts',
        ],
        rules: {
            'no-restricted-syntax': [
                'error',
                {
                    selector: 'ClassDeclaration',
                    message: 'Describe models with interfaces. Keep behavior in pure functions.',
                },
                {
                    selector: 'ClassExpression',
                    message: 'Describe models with interfaces. Keep behavior in pure functions.',
                },
            ],
        },
    },
    {
        files: ['src/controllers/**/*.ts'],
        rules: {
            'no-restricted-imports': [
                'error',
                {
                    patterns: [
                        'react',
                        'react-dom',
                        'react-dom/*',
                        'dexie',
                        '**/storage/SessionRepository',
                        '**/storage/queries',
                        '**/views/**',
                        '**/app/context',
                        '**/app/useController',
                    ],
                },
            ],
        },
    },
    {
        files: ['src/views/**/*.tsx'],
        rules: {
            'no-restricted-imports': [
                'error',
                { patterns: ['dexie', '**/storage', '**/storage/**'] },
            ],
        },
    },
    {
        files: ['src/app/**/*.{ts,tsx}'],
        rules: {
            'no-restricted-imports': [
                'error',
                { patterns: ['dexie', '**/storage/SessionRepository'] },
            ],
        },
    },
    prettier,
    {
        files: ['**/*.{js,ts,tsx}'],
        plugins: { '@stylistic': stylistic },
        rules: {
            '@stylistic/padding-line-between-statements': [
                'error',
                { blankLine: 'always', prev: 'import', next: '*' },
                { blankLine: 'any', prev: 'import', next: 'import' },
                { blankLine: 'always', prev: '*', next: 'return' },
            ],
            '@stylistic/lines-between-class-members': [
                'error',
                'always',
                { exceptAfterSingleLine: true },
            ],
        },
    },
);
