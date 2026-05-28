import { useQuery, type UseQueryReturn } from '@pinia/colada'
import { executeQuery, type NormalizedError } from './graphql'
import type { MaybeRefOrGetter } from 'vue'
import { toValue } from 'vue'

export interface ExamSession {
  studentId: string
  sentinelId: string
  examId: string
  videoFilePath: string | null
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
      user {
        preferredUsername
        givenName
        familyName
      }
    }
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
