<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { storeToRefs } from 'pinia'

const store = useWebsocketStore()
const { sentinelList, subscribedSentinel, frameContent } = storeToRefs(store) // refs
const { subscribeToSentinel } = store // functions
</script>

<template>
  <h1>Select your sentinel</h1>
  <p1>currently selected: {{ subscribedSentinel ?? 'No sentinel selected' }}</p1>
  <ul>
    <button
      :class="{ highlighted: sentinel == subscribedSentinel }"
      v-for="sentinel in sentinelList"
      :key="sentinel"
      @click="subscribeToSentinel(sentinel)"
    >
      {{ sentinel }}
    </button>
  </ul>

  <img :src="'data:image/png;base64,' + frameContent" alt="">
</template>

<style scoped>
img{
  width: 15vw;
  height: 20vh;
}
</style>
