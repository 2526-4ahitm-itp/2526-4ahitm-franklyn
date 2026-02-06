<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'

const {subscribeToSentinel, sentinelList, subscribedSentinel} = useWebsocketStore()
</script>

<template>
  <h1>Select your sentinel</h1>
  <p1>currently selected: {{ subscribedSentinel ?? 'No sentinel selected' }}</p1>
  {{sentinelList}}
<ul>
  <button v-for="sentinel in sentinelList" :key="sentinel" @click="subscribeToSentinel(sentinel)">{{ sentinel }}</button>
</ul>
</template>

<style scoped>
</style>

