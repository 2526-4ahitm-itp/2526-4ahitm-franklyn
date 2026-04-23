export interface Exam {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: Date | null
  endTime: Date | null
  startedAt: Date | null
  endedAt: Date | null
}
