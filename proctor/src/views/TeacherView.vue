<script setup lang="ts">
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'

const { result } = useQuery(gql`
  query getTeachers {
    teachers {
      id
      name
    }
  }
`)
</script>

<template>
  <ul>
    <li v-for="teacher of result.teachers" :key="teacher.id">
      {{ teacher.name }} {{ teacher.id }}
    </li>
  </ul>
</template>
