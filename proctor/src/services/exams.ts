import {
  useMutation,
  useQuery,
  useQueryCache,
  type UseMutationReturn,
  type UseQueryReturn,
} from '@pinia/colada'
import { executeMutation, executeQuery, type NormalizedError } from './graphql'
import type { Exam } from '@/types/Exam'
import type { MaybeRefOrGetter } from 'vue'
import { toValue } from 'vue'

const EXAMS_KEY = ['exams'] as const

const EXAMS_QUERY = /* GraphQL */ `
  query GetExams {
    exams {
      id
      title
      pin
      teacherId
      startTime
      endTime
      startedAt
      endedAt
    }
  }
`

const EXAM_QUERY = /* GraphQL */ `
  query GetExam($id: String!) {
    examId(id: $id) {
      id
      title
      pin
      teacherId
      startTime
      endTime
      startedAt
      endedAt
    }
  }
`

const CREATE_EXAM_MUTATION = /* GraphQL */ `
  mutation CreateExam($exam: InsertExamInput!) {
    createExam(examInput: $exam) {
      id
      title
      pin
      teacherId
      startTime
      endTime
      startedAt
      endedAt
    }
  }
`

const UPDATE_EXAM_SCHEDULE_MUTATION = /* GraphQL */ `
  mutation UpdateExamSchedule($examId: String!, $examScheduleInput: UpdateExamScheduleInput!) {
    updateExamSchedule(examId: $examId, examScheduleInput: $examScheduleInput) {
      id
      title
      startTime
      endTime
    }
  }
`

const DELETE_EXAM_MUTATION = /* GraphQL */ `
  mutation DeleteExam($id: String!) {
    deleteExam(id: $id)
  }
`

const START_EXAM_MUTATION = /* GraphQL */ `
  mutation StartExam($examId: String!) {
    startExam(examId: $examId) {
      id
      startedAt
    }
  }
`

const END_EXAM_MUTATION = /* GraphQL */ `
  mutation EndExam($examId: String!) {
    endExam(examId: $examId) {
      id
      endedAt
    }
  }
`

interface RawExam {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: string
  endTime: string
  startedAt: string | null
  endedAt: string | null
}

function mapExam(raw: RawExam): Exam {
  return {
    ...raw,
    startTime: new Date(raw.startTime),
    endTime: new Date(raw.endTime),
    startedAt: raw.startedAt ? new Date(raw.startedAt) : null,
    endedAt: raw.endedAt ? new Date(raw.endedAt) : null,
  }
}

export function useExamList(): UseQueryReturn<Exam[], NormalizedError> {
  return useQuery<Exam[], NormalizedError>({
    key: EXAMS_KEY,
    query: async () => {
      const data = await executeQuery<{ exams: RawExam[] }>(EXAMS_QUERY)
      return data.exams.map(mapExam)
    },
  })
}

export function useExam(id: MaybeRefOrGetter<string>): UseQueryReturn<Exam, NormalizedError> {
  return useQuery<Exam, NormalizedError>({
    key: () => ['exams', toValue(id)],
    query: async () => {
      const data = await executeQuery<{ examId: RawExam }, { id: string }>(EXAM_QUERY, {
        id: toValue(id),
      })
      return mapExam(data.examId)
    },
  })
}

export interface CreateExamInput {
  title: string
  startTime: Date
  endTime: Date
}

interface CreateExamInputPayload {
  title: string
  startTime: string
  endTime: string
}

export function useCreateExam(): UseMutationReturn<Exam, CreateExamInput, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<Exam, CreateExamInput, NormalizedError>({
    key: EXAMS_KEY,
    mutation: async (input) => {
      const data = await executeMutation<{ createExam: RawExam }, { exam: CreateExamInputPayload }>(
        CREATE_EXAM_MUTATION,
        {
          exam: {
            title: input.title,
            startTime: input.startTime.toISOString(),
            endTime: input.endTime.toISOString(),
          },
        },
      )
      return mapExam(data.createExam)
    },
    onSettled: () => {
      void queryCache.invalidateQueries({ key: EXAMS_KEY })
    },
  })
}

export interface UpdateExamScheduleInput {
  examId: string
  startTime: Date
  endTime: Date
}

interface UpdateExamScheduleInputPayload {
  startTime: string
  endTime: string
}

interface RawUpdateScheduleResponse {
  id: string
  title: string
  startTime: string
  endTime: string
}

export function useUpdateExamSchedule(): UseMutationReturn<
  { id: string; title: string; startTime: Date; endTime: Date },
  UpdateExamScheduleInput,
  NormalizedError
> {
  const queryCache = useQueryCache()
  return useMutation<
    { id: string; title: string; startTime: Date; endTime: Date },
    UpdateExamScheduleInput,
    NormalizedError
  >({
    mutation: async (input) => {
      const data = await executeMutation<
        { updateExamSchedule: RawUpdateScheduleResponse },
        { examId: string; examScheduleInput: UpdateExamScheduleInputPayload }
      >(UPDATE_EXAM_SCHEDULE_MUTATION, {
        examId: input.examId,
        examScheduleInput: {
          startTime: input.startTime.toISOString(),
          endTime: input.endTime.toISOString(),
        },
      })
      const res = data.updateExamSchedule
      return {
        id: res.id,
        title: res.title,
        startTime: new Date(res.startTime),
        endTime: new Date(res.endTime),
      }
    },
    onSettled: (data, error, variables) => {
      void queryCache.invalidateQueries({ key: EXAMS_KEY })
      void queryCache.invalidateQueries({ key: ['exams', variables.examId] })
    },
  })
}

export function useDeleteExam(): UseMutationReturn<boolean, string, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<boolean, string, NormalizedError>({
    mutation: async (id) => {
      const data = await executeMutation<{ deleteExam: boolean }, { id: string }>(
        DELETE_EXAM_MUTATION,
        { id },
      )
      return data.deleteExam
    },
    onSuccess: (data, id) => {
      const entry = queryCache.get(['exams', id])
      if (entry) {
        queryCache.remove(entry)
      }
    },
    onSettled: () => {
      void queryCache.invalidateQueries({ key: EXAMS_KEY })
    },
  })
}

interface RawStartExamResponse {
  id: string
  startedAt: string
}

export function useStartExam(): UseMutationReturn<
  { id: string; startedAt: Date },
  string,
  NormalizedError
> {
  const queryCache = useQueryCache()
  return useMutation<{ id: string; startedAt: Date }, string, NormalizedError>({
    mutation: async (examId) => {
      const data = await executeMutation<{ startExam: RawStartExamResponse }, { examId: string }>(
        START_EXAM_MUTATION,
        { examId },
      )
      const res = data.startExam
      return {
        id: res.id,
        startedAt: new Date(res.startedAt),
      }
    },
    onSettled: (data, error, examId) => {
      void queryCache.invalidateQueries({ key: EXAMS_KEY })
      void queryCache.invalidateQueries({ key: ['exams', examId] })
    },
  })
}

interface RawEndExamResponse {
  id: string
  endedAt: string
}

export function useEndExam(): UseMutationReturn<
  { id: string; endedAt: Date },
  string,
  NormalizedError
> {
  const queryCache = useQueryCache()
  return useMutation<{ id: string; endedAt: Date }, string, NormalizedError>({
    mutation: async (examId) => {
      const data = await executeMutation<{ endExam: RawEndExamResponse }, { examId: string }>(
        END_EXAM_MUTATION,
        { examId },
      )
      const res = data.endExam
      return {
        id: res.id,
        endedAt: new Date(res.endedAt),
      }
    },
    onSettled: (data, error, examId) => {
      void queryCache.invalidateQueries({ key: EXAMS_KEY })
      void queryCache.invalidateQueries({ key: ['exams', examId] })
    },
  })
}
