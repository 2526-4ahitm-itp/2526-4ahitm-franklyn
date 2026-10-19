export type NoticeType = 'ALERT' | 'TIMED' | 'SINGLE'

export interface NoticeContent {
  language: string
  content: string
}

export interface Notice {
  id: string
  type: NoticeType
  startTime: Date | null
  endTime: Date | null
  contents: NoticeContent[]
}

/**
 * Returns the notice text for `language`, falling back to any other available language.
 */
export function resolveNoticeContent(notice: Pick<Notice, 'contents'>, language: string): string {
  return (
    notice.contents.find((entry) => entry.language === language)?.content ??
    notice.contents[0]?.content ??
    ''
  )
}
