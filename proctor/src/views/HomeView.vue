<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { storeToRefs } from 'pinia'

const store = useWebsocketStore()
const { sentinelList, frameContent } = storeToRefs(store) // refs
// const { subscribeToSentinel } = store
</script>

<template>
  <div class="image-wrapper">
    <img
      v-for="sentinel in sentinelList"
      :key="sentinel"
      :src="'data:image/png;base64,' + frameContent"
      alt=""
    />
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

body {
  margin: 0;
}


.image-wrapper {
  height: 100vh;
  width: 100vw;
  position: relative;
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  top: 2vh;
  flex-wrap: wrap;

  img {
    height: 40%;
    width: 30%;
    object-fit: contain;
  }
}
</style>
