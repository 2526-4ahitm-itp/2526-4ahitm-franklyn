import { i18n } from '@/i18n'

export function toDate(value: Date | string | null | undefined): Date | null {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return isNaN(date.getTime()) ? null : date
}

export function formatExamRange(
  startTime: Date | string | null | undefined,
  endTime: Date | string | null | undefined,
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

export function formatDateLocal(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function formatTime(date: Date): string {
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
}
