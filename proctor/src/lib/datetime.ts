import { i18n } from '@/i18n'

export function toDate(value: Date | string | null | undefined): Date | null {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return isNaN(date.getTime()) ? null : date
}

export function formatExamRange(
  startTime: Date | string | null | undefined,
  endTime: Date | string | null | undefined
): string {
  const start = toDate(startTime)
  const end = toDate(endTime)

  if (start && end) {
    return (
      i18n.global.d(start, 'short') +
      ' · ' +
      i18n.global.d(start, 'time') +
      ' – ' +
      i18n.global.d(end, 'time')
    )
  }
  if (start) {
    return i18n.global.d(start, 'short') + ' · ' + i18n.global.d(start, 'time')
  }
  return i18n.global.t('exams.not_scheduled')
}
