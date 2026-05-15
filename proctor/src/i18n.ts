import { nextTick } from 'vue'
import {createI18n} from 'vue-i18n'
import type { I18n } from 'vue-i18n'

export const SUPPORT_LOCALES = ['en', 'de']

export function setupI18n(options = { locale: 'en' }) : I18n {
  const i18n = createI18n(options)
  setI18nLanguage(i18n, options.locale)
  return i18n
}

export function setI18nLanguage(i18n : I18n, locale : string): void{

  i18n.global.locale = locale
  const html = document.querySelector('html');
  if(html) {
    html.setAttribute('lang', locale)
  }
}

export async function loadLocaleMessages(i18n : I18n, locale : string): Promise<void> {
  // load locale messages with dynamic import
  const messages = await import(
    /* webpackChunkName: "locale-[request]" */ `./locales/${locale}.json`
    )

  // set locale and locale message
  i18n.global.setLocaleMessage(locale, messages.default)

  return nextTick()
}
