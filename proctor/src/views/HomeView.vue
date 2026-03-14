<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { storeToRefs } from 'pinia'

const store = useWebsocketStore()
const { currentPage, totalPages, pagedSentinels, framesBySentinel } = storeToRefs(store)
const { pageSize } = store
// refs
// const { subscribeToSentinel } = store
</script>

<template>
  <div class="proctor-view">
    <div class="frame-grid">
      <div v-for="sentinel in pagedSentinels" :key="sentinel.sentinelId" class="frame-card">
        <img
          v-if="framesBySentinel[sentinel.sentinelId]"
          :src="'data:image/jpeg;base64,' + framesBySentinel[sentinel.sentinelId]"
          :alt="`Sentinel ${sentinel.name} frame`"
        />
        <div v-else class="frame-placeholder">
          Waiting for frame
        </div>
        <p class="frame-label">{{ sentinel.name }}</p>
      </div>
    </div>
    <div class="pager">
      <button :disabled="currentPage === 0" @click="currentPage--">Previous</button>
      <span class="pager-info">Page {{ currentPage + 1 }} / {{ totalPages }}</span>
      <button :disabled="currentPage >= totalPages - 1" @click="currentPage++">Next</button>
    </div>
  </div>
</template>

<style scoped>
.proctor-view {
  min-height: 100vh;
  width: 100vw;
  padding: 1rem;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.75rem;
  background: #f5f6f8;
}

.frame-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.4rem 1rem;
  justify-items: center;
  align-items: start;
  align-content: center;
}

.frame-card {
  display: flex;
  flex-direction: column;
  border-radius: 6px;
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.08);
  padding: 0.35rem;
  gap: 0.35rem;
  width: 100%;
}

.frame-card img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  display: block;
  border-radius: 4px;
  background: #f0f1f3;
}

.frame-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  padding: 0.75rem 0.5rem;
  border-radius: 4px;
  background: #f0f1f3;
  width: 100%;
  aspect-ratio: 16 / 9;
}

.frame-label {
  padding: 0.15rem 0;
  font-size: 0.95rem;
  text-align: center;
  word-break: break-all;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}

.frame-empty {
}

.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.pager button {
  padding: 0.4rem 0.8rem;
  border-radius: 0;
  border: 1px solid currentColor;
  background-color: transparent;
  color: inherit;
  cursor: pointer;
  transition: background-color 0.15s, border-color 0.15s;
}

.pager button:disabled {
  cursor: not-allowed;
}

.pager-info {
  font-size: 0.9rem;
}

@media (max-width: 900px) {
  .frame-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 600px) {
  .frame-grid {
    grid-template-columns: 1fr;
  }
}
</style>
