import { createI18n } from 'vue-i18n'
import en from './locales/en.json'
import de from './locales/de.json'

export type MessageSchema = typeof en
export const i18n = createI18n({
  legacy: false,      // Composition API mode — always use this for Vue 3
  locale: 'en',
  fallbackLocale: 'de',
  globalInjection: true, // Makes $t available in templates globally
  messages: { en, de },
})
