<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { storeToRefs } from 'pinia'

const store = useWebsocketStore()
const { sentinelList, subscribedSentinel, frameContent } = storeToRefs(store) // refs
const { subscribeToSentinel } = store // functions
</script>

<template>
  <div class="wrapper">
    <div class="sidebar">
      <button
        :class="{ highlighted: sentinel == subscribedSentinel }"
        v-for="sentinel in sentinelList"
        :key="sentinel"
        @click="subscribeToSentinel(sentinel)"
      >
        {{ sentinel }}
      </button>
    </div>

    <img :src="'data:image/png;base64,' + frameContent" alt="" />
  </div>
</template>

<style scoped>
img {
  width: 15vw;
  height: 20vh;
}

.sidebar {
  height: 100vh;
  width: 400px;
  position: relative;
  display: flex;
  flex-direction: column;
  background-color: rgb(22, 34, 62);
  padding: 0.8rem;
}

button {
  display: inline-block;
  padding: 0.5rem 0.8rem;
  background-color: hsl(210, 85%, 55%);
  border-radius: 0.5rem;
  border: none;
  color: white;
  margin: 0.2rem;
  cursor: pointer;
  transition: background-color 0.1s;
}

.highlighted {
  background-color: hsl(185, 72%, 45%);
}

body {
  margin: 0;
}

.wrapper {
  height: 100vh;
  width: 100vw;
  display: flex;
}
</style>
