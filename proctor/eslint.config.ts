import { globalIgnores } from 'eslint/config'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import pluginVue from 'eslint-plugin-vue'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'

export default defineConfigWithVueTs(
  {
    name: 'app/files-to-lint',
    files: ['**/*.{ts,mts,tsx,vue}'],
    rules: {
      // --------------------
      // Naming conventions
      // --------------------
      '@typescript-eslint/naming-convention': [
        'error',
        { selector: 'variable', format: ['camelCase'] },
        { selector: 'variableLike', format: ['camelCase', 'UPPER_CASE'] },
        { selector: 'function', format: ['camelCase'] },
        { selector: 'typeLike', format: ['PascalCase'] },
        { selector: 'enumMember', format: ['PascalCase', 'UPPER_CASE'] },
      ],

      // --------------------
      // Prettier formatting
      // --------------------
      'prettier/prettier': 'error',

      // --------------------
      // TypeScript strictness
      // --------------------
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-module-boundary-types': 'error',
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/strict-boolean-expressions': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-unnecessary-type-assertion': 'error',
      '@typescript-eslint/prefer-nullish-coalescing': 'error',
      '@typescript-eslint/prefer-optional-chain': 'error',

      // --------------------
      // Vue strictness & best practices
      // --------------------
      'vue/multi-word-component-names': 'error',
      'vue/require-prop-types': 'error',
      'vue/require-default-prop': 'error',
      'vue/enforce-style-attribute': [
        'error',
        {
          allow: ['scoped'],
        },
      ],
      'vue/component-api-style': ['error', ['script-setup']],
      'vue/block-order': ['error', { order: ['script', 'template', 'style'] }],
      'vue/no-unused-refs': 'error',
      'vue/no-ref-as-operand': 'error',
      'vue/require-explicit-emits': 'error',
      'vue/no-mutating-props': 'error',
      'vue/no-v-html': 'error',
      'vue/prop-name-casing': ['error', 'camelCase'],
      'vue/component-name-in-template-casing': ['error', 'PascalCase'],

      // --------------------
      // Error handling & resilience
      // --------------------
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-debugger': 'error',
      'no-throw-literal': 'error',

      // --------------------
      // Code quality & maintainability
      // --------------------
      'no-nested-ternary': 'error',
      'prefer-const': 'error',
      'no-var': 'error',
      eqeqeq: ['error', 'always'],
      'no-eval': 'error',
      'no-implied-eval': 'error',
    },
  },

  globalIgnores(['**/dist/**', '**/dist-ssr/**', '**/coverage/**']),

  // Use stricter recommended configs
  pluginVue.configs['flat/strongly-recommended'],
  vueTsConfigs.strict,
  skipFormatting,
)
