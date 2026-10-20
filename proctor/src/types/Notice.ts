export type NoticeType = 'ALERT' | 'TIMED' | 'SINGLE'

export interface Notice {
  id: string
  type: NoticeType
  startTime: Date | null
  endTime: Date | null
  content: string
}

/** Notice text per language code, stored as JSON in `Notice.content`. */
export type NoticeTranslations = Record<string, string>

/**
 * Parses `Notice.content` as translations. Returns `null` for plain-text content
 * written before notices supported multiple languages.
 */
export function parseNoticeContent(content: string): NoticeTranslations | null {
  let parsed: unknown
  try {
    parsed = JSON.parse(content)
  } catch {
    return null
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) return null
  const entries = Object.entries(parsed)
  if (entries.length === 0 || entries.some(([, value]) => typeof value !== 'string')) return null
  return Object.fromEntries(entries) as NoticeTranslations
}

export function serializeNoticeContent(translations: NoticeTranslations): string {
  return JSON.stringify(translations)
}

/**
 * Returns the notice text for `language`, falling back to any other available language.
 */
export function resolveNoticeContent(content: string, language: string): string {
  const translations = parseNoticeContent(content)
  if (!translations) return content
  return translations[language] ?? Object.values(translations)[0] ?? ''
}
