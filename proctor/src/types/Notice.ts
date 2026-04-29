export type NoticeType = 'ALERT' | 'TIMED' | 'SINGLE'

export interface Notice {
  id: string
  type: NoticeType
  startTime: Date | null
  endTime: Date | null
  content: string
}
