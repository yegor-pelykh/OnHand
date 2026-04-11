import tsParser from '@typescript-eslint/parser';
import ngParser from '@angular-eslint/template-parser';
import js from '@eslint/js';
import ts from '@typescript-eslint/eslint-plugin';
import ng from '@angular-eslint/eslint-plugin';
import ngTemplate from '@angular-eslint/eslint-plugin-template';
import globals from 'globals';
import prettierRecommended from 'eslint-plugin-prettier/recommended';

export default [
  {
    files: ['**/*.ts'],
    plugins: {
      '@typescript-eslint': ts,
      '@angular-eslint': ng,
      '@angular-eslint/template': ngTemplate,
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.webextensions,
      },
      parser: tsParser,
      parserOptions: {
        project: [
          './tsconfig.root.json',
          './projects/content/tsconfig.content.json',
          './projects/popup/tsconfig.popup.json',
          './projects/sw/tsconfig.sw.json',
          './shared/tsconfig.shared.json',
        ],
        sourceType: 'module',
        ecmaVersion: 2020,
      },
    },
    rules: {
      ...js.configs.recommended.rules,
      ...ts.configs['recommended-requiring-type-checking'].rules,
      ...ts.configs['stylistic-type-checked'].rules,
      ...ng.configs.recommended.rules,
      'no-console': 'error',
      'prefer-const': 'error',
      'arrow-body-style': ['error', 'as-needed'],
      '@angular-eslint/directive-class-suffix': 'error',
      '@angular-eslint/directive-selector': [
        'error',
        {
          type: 'attribute',
          prefix: 'app',
          style: 'camelCase',
        },
      ],
      '@angular-eslint/component-class-suffix': [
        'error',
        {
          suffixes: ['Component', 'Dialog'],
        },
      ],
      '@angular-eslint/component-selector': [
        'error',
        {
          type: 'element',
          prefix: 'app',
          style: 'kebab-case',
        },
      ],
      '@typescript-eslint/explicit-function-return-type': 'error',
      '@typescript-eslint/no-inferrable-types': ['error'],
      '@typescript-eslint/no-unnecessary-type-assertion': 'error',
      '@typescript-eslint/no-unnecessary-type-arguments': 'error',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/member-ordering': 'error',
      '@typescript-eslint/unbound-method': [
        'error',
        {
          ignoreStatic: true,
        },
      ],
      'sort-imports': [
        'error',
        {
          ignoreDeclarationSort: true,
        },
      ],
    },
  },
  {
    files: ['**/*.html'],
    plugins: {
      '@angular-eslint/template': ngTemplate,
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.webextensions,
      },
      parser: ngParser,
    },
    rules: {
      ...ngTemplate.configs.recommended.rules,
      ...ngTemplate.configs.accessibility.rules,
      '@angular-eslint/template/no-any': 'error',
    },
  },
  prettierRecommended,
];
