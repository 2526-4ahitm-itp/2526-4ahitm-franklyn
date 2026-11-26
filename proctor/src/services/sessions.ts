import {
  useQuery,
  useMutation,
  useQueryCache,
  type UseQueryReturn,
  type UseMutationReturn,
} from '@pinia/colada'
import { executeQuery, executeMutation, type NormalizedError } from './graphql'
import type { MaybeRefOrGetter } from 'vue'
import { toValue } from 'vue'

export type VideoStatus = 'PENDING' | 'DONE' | 'FAILED'

export interface ExamSession {
  studentId: string
  sentinelId: string
  examId: string
  videoFilePath: string | null
  videoStatus: VideoStatus | null
  user: {
    preferredUsername: string
    givenName: string | null
    familyName: string | null
  }
}

const ALL_STUDENTS_QUERY = /* GraphQL */ `
  query AllStudents($examId: String!) {
    allStudents(examId: $examId) {
      studentId
      sentinelId
      examId
      videoFilePath
      videoStatus
      user {
        preferredUsername
        givenName
        familyName
      }
    }
  }
`

const GENERATE_VIDEO_MUTATION = /* GraphQL */ `
  mutation GenerateSentinelVideo($sentinelId: String!) {
    generateSentinelVideo(sentinelId: $sentinelId)
  }
`

export function useExamSessions(
  examId: MaybeRefOrGetter<string>,
): UseQueryReturn<ExamSession[], NormalizedError> {
  return useQuery<ExamSession[], NormalizedError>({
    key: () => ['sessions', toValue(examId)],
    query: async () => {
      const data = await executeQuery<{ allStudents: ExamSession[] }, { examId: string }>(
        ALL_STUDENTS_QUERY,
        { examId: toValue(examId) },
      )
      return data.allStudents
    },
  })
}

export function useGenerateSentinelVideo(
  examId: string,
): UseMutationReturn<null, string, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<null, string, NormalizedError>({
    mutation: async (sentinelId) => {
      await executeMutation<unknown, { sentinelId: string }>(GENERATE_VIDEO_MUTATION, {
        sentinelId,
      })
      return null
    },
    onSettled: () => queryCache.invalidateQueries({ key: ['sessions', examId] }),
  })
}

export interface NamedExamSession extends ExamSession {
  sessionIndex: number
  studentName: string
}

export interface StudentSessions {
  studentId: string
  name: string
  sessions: NamedExamSession[]
}

function studentName(session: ExamSession): string {
  if (!session.user) return session.studentId.slice(0, 8)
  const { givenName, familyName, preferredUsername } = session.user
  return [givenName, familyName].filter(Boolean).join(' ') || preferredUsername
}

export function nameSessions(sessions: ExamSession[]): NamedExamSession[] {
  const sessionsPerStudent: Record<string, number> = {}
  return [...sessions]
    .sort((a, b) => a.sentinelId.localeCompare(b.sentinelId))
    .map((s) => {
      const sessionIndex = sessionsPerStudent[s.studentId] ?? 0
      sessionsPerStudent[s.studentId] = sessionIndex + 1
      return {
        ...s,
        sessionIndex,
        studentName: studentName(s),
      }
    })
}

/** Orders students alphabetically by display name (locale-aware, numeric-aware). */
export function compareStudentsByName(a: StudentSessions, b: StudentSessions): number {
  return (
    a.name.localeCompare(b.name, undefined, { sensitivity: 'base', numeric: true }) ||
    a.studentId.localeCompare(b.studentId)
  )
}

export function groupSessionsByStudent(sessions: ExamSession[]): StudentSessions[] {
  const groups = new Map<string, StudentSessions>()
  for (const session of nameSessions(sessions)) {
    const group = groups.get(session.studentId)
    if (group) {
      group.sessions.push(session)
    } else {
      groups.set(session.studentId, {
        studentId: session.studentId,
        name: session.studentName,
        sessions: [session],
      })
    }
  }
  return [...groups.values()]
}
