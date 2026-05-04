import { gql } from '@apollo/client'
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import type { Notice, NoticeType } from '@/types/Notice'

export const useNoticeStore = defineStore('notice', () => {
  const { client } = useApolloClientStore()

  const notices = ref<Notice[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchNotices() {
    loading.value = true
    error.value = null
    try {
      const res = await client.query<{ notices: Notice[] }>({
        query: gql`
          query GetNotices {
            notices {
              id
              type
              startTime
              endTime
              content
            }
          }
        `,
        fetchPolicy: 'network-only',
      })
      if (res.data?.notices) notices.value = [...res.data.notices]
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch notices'
      error.value = message
      if (message.includes('403')) {
        error.value = 'Not authorized to view notices.'
      }
      console.error(err)
    } finally {
      loading.value = false
    }
  }

  async function createNotice(input: {
    type: NoticeType
    content: string
    startTime: Date | null
    endTime: Date | null
  }) {
    loading.value = true
    error.value = null
    try {
      const res = await client.mutate<{ createNotice: Notice }>({
        mutation: gql`
          mutation CreateNotice($notice: InsertNoticeInput!) {
            createNotice(insertNotice: $notice) {
              id
              type
              startTime
              endTime
              content
            }
          }
        `,
        variables: {
          notice: {
            type: input.type,
            content: input.content,
            startTime: input.startTime?.toISOString(),
            endTime: input.endTime?.toISOString(),
          },
        },
      })
      if (res.data?.createNotice) {
        notices.value = [res.data.createNotice, ...notices.value]
        return res.data.createNotice
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create notice'
      error.value = message
      console.error(err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateNotice(input: {
    id: string
    content: string
    startTime: Date | null
    endTime: Date | null
  }) {
    loading.value = true
    error.value = null
    try {
      const res = await client.mutate<{ updateNotice: Notice }>({
        mutation: gql`
          mutation UpdateNotice($id: String!, $notice: UpdateNoticeInput!) {
            updateNotice(id: $id, updateNotice: $notice) {
              id
              type
              startTime
              endTime
              content
            }
          }
        `,
        variables: {
          id: input.id,
          notice: {
            content: input.content,
            startTime: input.startTime?.toISOString(),
            endTime: input.endTime?.toISOString(),
          },
        },
      })
      const updatedNotice = res.data?.updateNotice
      if (updatedNotice) {
        notices.value = notices.value.map((notice) =>
          notice.id === updatedNotice.id ? updatedNotice : notice,
        )
        return updatedNotice
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update notice'
      if (!message.includes('Unknown type')) {
        error.value = message
      }
      console.error(err)
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteNotice(id: string) {
    loading.value = true
    error.value = null
    try {
      await client.mutate({
        mutation: gql`
          mutation DeleteNotice($id: String!) {
            deleteNotice(id: $id)
          }
        `,
        variables: {
          id,
        },
      })
      notices.value = notices.value.filter((notice) => notice.id !== id)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete notice'
      error.value = message
      console.error(err)
      throw err
    } finally {
      loading.value = false
    }
  }

  return { notices, loading, error, fetchNotices, createNotice, updateNotice, deleteNotice }
})
