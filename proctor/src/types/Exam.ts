export interface Exam {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: Date
  endTime: Date
  startedAt: Date | null
  endedAt: Date | null
}

