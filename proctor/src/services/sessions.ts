import { useQuery, useMutation, useQueryCache, type UseQueryReturn, type UseMutationReturn } from '@pinia/colada'
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

export function useGenerateSentinelVideo(examId: string): UseMutationReturn<null, string, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<null, string, NormalizedError>({
    mutation: async (sentinelId) => {
      await executeMutation<unknown, { sentinelId: string }>(GENERATE_VIDEO_MUTATION, { sentinelId })
      return null
    },
    onSettled: () => queryCache.invalidateQueries({ key: ['sessions', examId] }),
  })
}
