<script setup lang="ts">
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { provideApolloClient } from '@vue/apollo-composable'
import { apolloClient } from '../stores/ApolloClient.ts'

provideApolloClient(apolloClient)

const { result, loading, error } = useQuery(gql`
  query getTeachers {
    teachers {
      id
      name
    }
  }
`)
</script>

<template>
  <div v-if="loading">Loading query...</div>
  <div v-else-if="error">An error has occurred: {{error.message}}</div>

  <ul v-else>
    <li v-for="teacher of result?.teachers || []" :key="teacher.id">
      {{ teacher.name }} {{ teacher.id }}
    </li>
  </ul>
</template>
