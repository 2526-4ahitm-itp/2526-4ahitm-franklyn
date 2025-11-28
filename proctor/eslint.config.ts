import { globalIgnores } from 'eslint/config'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import pluginVue from 'eslint-plugin-vue'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'

// To allow more languages other than `ts` in `.vue` files, uncomment the following lines:
// import { configureVueProject } from '@vue/eslint-config-typescript'
// configureVueProject({ scriptLangs: ['ts', 'tsx'] })
// More info at https://github.com/vuejs/eslint-config-typescript/#advanced-setup

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

      // --------------------
      // Vue strictness
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
    },
  },

  globalIgnores(['**/dist/**', '**/dist-ssr/**', '**/coverage/**']),

  pluginVue.configs['flat/essential'],
  vueTsConfigs.recommended,
  skipFormatting,
)
