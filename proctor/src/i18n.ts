import { createI18n } from 'vue-i18n'

import en from './locales/en.json'
import de from './locales/de.json'

export type MessageSchema = typeof en

export const i18n = createI18n({
  locale: 'en',
  fallbackLocale: 'de',
  globalInjection: true, // Makes $t available in templates globally
  messages: { en, de },
  datetimeFormats: {
    en: {
      short: {
        month: 'short',
        day: 'numeric',
      },
      long: {
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        hour12: true,
      },
      time: {
        hour: 'numeric',
        minute: 'numeric',
        hour12: true,
      },
      datetime: {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      },
    },
    de: {
      short: {
        day: 'numeric',
        month: 'short',
      },
      long: {
        day: 'numeric',
        month: 'short',
        hour: 'numeric',
        minute: 'numeric',
      },
      time: {
        hour: 'numeric',
        minute: 'numeric',
      },
      datetime: {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      },
    },
  },
})
