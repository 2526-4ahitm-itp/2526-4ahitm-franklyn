import { computed, toValue, watch, type ComputedRef, type MaybeRefOrGetter } from 'vue'
import { storeToRefs } from 'pinia'
import { useExam } from './exams'
import {
  compareStudentsByName,
  groupSessionsByStudent,
  useExamSessions,
  type StudentSessions,
} from './sessions'
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { toDate } from '@/lib/datetime'
import { buildTimeline, type SessionTimes } from '@/lib/presenceTimeline'

export interface ExamEvent {
  id: string
  type: 'join' | 'leave'
  studentId: string
  name: string
  time: Date
  exact: boolean
}

export interface ExamStudent extends StudentSessions {
  present: boolean
}

interface ExamEventsApi {
  students: ComputedRef<ExamStudent[]>
  sentinelIds: ComputedRef<string[]>
  sessionTimes: ComputedRef<Map<string, SessionTimes>>
  events: ComputedRef<ExamEvent[]>
  currentStudentCount: ComputedRef<number>
  peakStudentCount: ComputedRef<number>
}

const UNKNOWN_SENTINEL_RETRY_MS = 1500

export function useExamEvents(examId: MaybeRefOrGetter<string>): ExamEventsApi {
  const sessionsQuery = useExamSessions(examId)
  const { data: examData } = useExam(() => toValue(examId))
  const { onlineSentinelIds, sentinelJournal, presenceKnown } = storeToRefs(useWebsocketStore())

  const groups = computed(() => groupSessionsByStudent(sessionsQuery.data.value ?? []))
  const sentinelIds = computed(() =>
    groups.value.flatMap((group) => group.sessions.map((s) => s.sentinelId)),
  )

  const firstComputedAt = new Map<string, number>()
  function fallbackTime(key: string): number {
    const known = firstComputedAt.get(key)
    if (known !== undefined) return known
    const now = Date.now()
    firstComputedAt.set(key, now)
    return now
  }

  const timeline = computed(() =>
    buildTimeline({
      sessions: groups.value.flatMap((group) => group.sessions),
      journal: sentinelJournal.value,
      presenceKnown: presenceKnown.value,
      onlineIds: onlineSentinelIds.value,
      examStart: toDate(examData.value?.startedAt ?? null)?.getTime() ?? null,
      examEnd: toDate(examData.value?.endedAt ?? null)?.getTime() ?? null,
      fallbackTime,
    }),
  )

  const names = computed(() => new Map(groups.value.map((g) => [g.studentId, g.name])))

  const students = computed<ExamStudent[]>(() =>
    groups.value
      .map((group) => ({
        ...group,
        present: timeline.value.presentStudentIds.has(group.studentId),
      }))
      .sort(compareStudentsByName),
  )

  const events = computed<ExamEvent[]>(() =>
    timeline.value.events.map((event) => ({
      ...event,
      name: names.value.get(event.studentId) ?? event.studentId,
      time: new Date(event.time),
    })),
  )

  const sessionTimes = computed(() => timeline.value.sessionTimes)
  const currentStudentCount = computed(() => timeline.value.presentStudentIds.size)
  const peakStudentCount = computed(() => timeline.value.peakStudentCount)

  let lastUnknownKey = ''
  let retryTimeout: ReturnType<typeof setTimeout> | null = null

  watch(
    [onlineSentinelIds, sentinelIds],
    ([online, known]) => {
      const knownIds = new Set(known)
      const unknownKey = [...online]
        .filter((id) => !knownIds.has(id))
        .sort()
        .join(',')
      if (!unknownKey || unknownKey === lastUnknownKey || !toValue(examId)) return
      lastUnknownKey = unknownKey
      void sessionsQuery.refetch()
      if (retryTimeout) clearTimeout(retryTimeout)
      retryTimeout = setTimeout(() => {
        retryTimeout = null
        void sessionsQuery.refetch()
      }, UNKNOWN_SENTINEL_RETRY_MS)
    },
    { immediate: true },
  )

  return { students, sentinelIds, sessionTimes, events, currentStudentCount, peakStudentCount }
}
