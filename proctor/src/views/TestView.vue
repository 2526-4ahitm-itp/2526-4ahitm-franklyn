<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref } from 'vue'

const { client } = useApolloClientStore()

interface Test {
  teacherId: string
  startTime: string
}

const testsList = ref<Test[]>([])

client
  .query<{
    tests: Test[]
  }>({
    query: gql`
      query GetTests {
        tests {
          teacherId
          startTime
        }
      }
    `,
  })
  .then((res) => {
    if (res.data?.tests !== undefined) {
      testsList.value = res.data?.tests
    }
  })
  .catch(() => {
    console.error('Failed to fetch tests!')
  })
</script>

<template>
  <pre>{{ JSON.stringify(testsList, null, 2) }}</pre>
</template>
