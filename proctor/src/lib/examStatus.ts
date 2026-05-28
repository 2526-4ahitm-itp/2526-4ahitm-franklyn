import { i18n } from '@/i18n'

export type ExamStatus = 'live' | 'completed' | 'scheduled'

export function getExamStatus(
  startedAt: Date | string | null | undefined,
  endedAt: Date | string | null | undefined,
): ExamStatus {
  if (!startedAt) return 'scheduled'
  if (!endedAt) return 'live'
  return 'completed'
}

export function examStatusTranslated(status: ExamStatus): string {
  if (status === 'scheduled') return i18n.global.t('exams.scheduled')
  if (status === 'live') return i18n.global.t('exams.live')
  return i18n.global.t('exams.completed')
}
