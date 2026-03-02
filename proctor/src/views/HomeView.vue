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
      <div v-for="sentinel in pagedSentinels" :key="sentinel" class="frame-card">
        <img
          v-if="framesBySentinel[sentinel]"
          :src="'data:image/png;base64,' + framesBySentinel[sentinel]"
          :alt="`Sentinel ${sentinel} frame`"
        />
        <div v-else class="frame-placeholder">
          Waiting for frame
        </div>
        <p class="frame-label">{{ sentinel }}</p>
      </div>
      <div
        v-for="index in Math.max(0, pageSize - pagedSentinels.length)"
        :key="`empty-${index}`"
        class="frame-card frame-empty"
      >
        <div class="frame-placeholder">No sentinel</div>
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
  padding: 1rem 1.5rem 2rem;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.frame-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
}

.frame-card {
  border: 1px solid #d2d8e4;
  border-radius: 0.75rem;
  overflow: hidden;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  min-height: 220px;
}

.frame-card img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  background: #0f172a;
  flex: 1;
}

.frame-placeholder {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  color: #64748b;
  background: linear-gradient(145deg, #e2e8f0, #f8fafc);
}

.frame-label {
  padding: 0.6rem 0.8rem;
  font-size: 0.75rem;
  color: #334155;
  border-top: 1px solid #e2e8f0;
  word-break: break-all;
}

.frame-empty {
  border-style: dashed;
  background: #f1f5f9;
}

.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.pager button {
  padding: 0.45rem 0.9rem;
  border-radius: 0.5rem;
  border: none;
  background-color: #2563eb;
  color: #fff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.pager button:disabled {
  cursor: not-allowed;
  background-color: #94a3b8;
}

.pager-info {
  font-size: 0.9rem;
  color: #334155;
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
