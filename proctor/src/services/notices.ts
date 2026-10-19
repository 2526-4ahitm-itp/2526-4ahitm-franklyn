import {
  useMutation,
  useQuery,
  useQueryCache,
  type UseMutationReturn,
  type UseQueryReturn,
} from '@pinia/colada'
import { executeMutation, executeQuery, type NormalizedError } from './graphql'
import type { Notice, NoticeType } from '@/types/Notice'

const NOTICES_KEY = ['notices'] as const

const NOTICES_QUERY = /* GraphQL */ `
  query Notices {
    notices {
      id
      type
      startTime
      endTime
      content
    }
  }
`

const CREATE_NOTICE_MUTATION = /* GraphQL */ `
  mutation CreateNotice($notice: InsertNoticeInput!) {
    createNotice(insertNotice: $notice) {
      id
      type
      startTime
      endTime
      content
    }
  }
`

const UPDATE_NOTICE_MUTATION = /* GraphQL */ `
  mutation UpdateNotice($id: String!, $notice: UpdateNoticeInput!) {
    updateNotice(id: $id, updateNotice: $notice) {
      id
      type
      startTime
      endTime
      content
    }
  }
`

const DELETE_NOTICE_MUTATION = /* GraphQL */ `
  mutation DeleteNotice($id: String!) {
    deleteNotice(id: $id)
  }
`

export function useNotices(): UseQueryReturn<Notice[], NormalizedError> {
  return useQuery<Notice[], NormalizedError>({
    key: NOTICES_KEY,
    query: async () => {
      const data = await executeQuery<{ notices: Notice[] }>(NOTICES_QUERY)
      return data.notices
    },
  })
}

export interface CreateNoticeInput {
  type: NoticeType
  content: string
  startTime: Date | null
  endTime: Date | null
}

interface NoticeInputPayload {
  type: NoticeType
  content: string
  startTime: string | null
  endTime: string | null
}

interface NoticePatchPayload {
  content: string
  startTime: string | null
  endTime: string | null
}

export function useCreateNotice(): UseMutationReturn<Notice, CreateNoticeInput, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<Notice, CreateNoticeInput, NormalizedError>({
    mutation: async (input) => {
      const data = await executeMutation<{ createNotice: Notice }, { notice: NoticeInputPayload }>(
        CREATE_NOTICE_MUTATION,
        {
          notice: {
            type: input.type,
            content: input.content,
            startTime: input.startTime?.toISOString() ?? null,
            endTime: input.endTime?.toISOString() ?? null,
          },
        },
      )
      return data.createNotice
    },
    onSettled: () => queryCache.invalidateQueries({ key: NOTICES_KEY }),
  })
}

export interface UpdateNoticeInput {
  id: string
  content: string
  startTime: Date | null
  endTime: Date | null
}

export function useUpdateNotice(): UseMutationReturn<Notice, UpdateNoticeInput, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<Notice, UpdateNoticeInput, NormalizedError>({
    mutation: async (input) => {
      const data = await executeMutation<
        { updateNotice: Notice },
        { id: string; notice: NoticePatchPayload }
      >(UPDATE_NOTICE_MUTATION, {
        id: input.id,
        notice: {
          content: input.content,
          startTime: input.startTime?.toISOString() ?? null,
          endTime: input.endTime?.toISOString() ?? null,
        },
      })
      return data.updateNotice
    },
    onSettled: () => queryCache.invalidateQueries({ key: NOTICES_KEY }),
  })
}

export function useDeleteNotice(): UseMutationReturn<null, string, NormalizedError> {
  const queryCache = useQueryCache()
  return useMutation<null, string, NormalizedError>({
    mutation: async (id) => {
      await executeMutation<{ deleteNotice: null }, { id: string }>(DELETE_NOTICE_MUTATION, { id })
      return null
    },
    onSettled: () => queryCache.invalidateQueries({ key: NOTICES_KEY }),
  })
}

