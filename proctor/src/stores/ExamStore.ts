import { defineStore } from 'pinia'
import { ref } from 'vue'
import { gql } from '@apollo/client'
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import type { Exam } from '@/types/Exam'

export const useExamStore = defineStore('exam', () => {
  const { client } = useApolloClientStore()

  const exams = ref<Exam[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchExams() {
    loading.value = true
    try {
      const res = await client.query<{ exams: Exam[] }>({
        query: gql`
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
        `,
        fetchPolicy: 'network-only',
      })
      if (res.data?.exams) exams.value = [...res.data.exams]
    } catch (e) {
      error.value = 'Failed to fetch exams'
      console.error(e)
    } finally {
      loading.value = false
    }
  }

  async function createExam(input: { title: string; startTime: Date; endTime: Date }) {
    loading.value = true

    try {
      const res = await client.mutate<{ createExam: Exam }>({
        mutation: gql`
          mutation CreateExam($exam: InsertExamInput!) {
            createExam(examInput: $exam) {
              id
            }
          }
        `,
        variables: {
          exam: {
            title: input.title,
            startTime: input.startTime.toISOString(),
            endTime: input.endTime.toISOString(),
          },
        },
      })
      if (res.data?.createExam) {
        exams.value.push(res.data.createExam)
        return res.data.createExam
      }
    } catch (e) {
      error.value = 'Failed to create exam!'
      console.error(e)
      throw e
    } finally {
      loading.value = false
    }
  }

  return { exams, loading, error, fetchExams, createExam }
})
