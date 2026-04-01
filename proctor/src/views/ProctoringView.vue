<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { storeToRefs } from 'pinia'
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const { client } = useApolloClientStore()
const store = useWebsocketStore()
const { currentPage, totalPages, pagedSentinels, framesBySentinel } = storeToRefs(store)
const { setProfile, setPin } = store

const testId = computed(() => route.params.id as string | undefined)
const testPin = ref<number | null>(null)

const expandedSentinelId = ref<string | null>(null)
const expandedSentinelName = ref<string>('')

onMounted(() => {
  if (testId.value) {
    client.query<{ testId: { pin: number } }>({
      query: gql`
        query GetTestPin($id: String!) {
          testId(id: $id) {
            pin
          }
        }
      `,
      variables: { id: testId.value },
      fetchPolicy: 'network-only'
    }).then(res => {
      if (res.data?.testId?.pin) {
        testPin.value = res.data.testId.pin
        setPin(res.data.testId.pin)
      }
    }).catch(e => {
      console.error('Failed to fetch test pin!', e)
    })
  }
})

function openSentinel(sentinelId: string, name: string) {
  expandedSentinelId.value = sentinelId
  expandedSentinelName.value = name
  setProfile(sentinelId, 'HIGH')
}

function closeSentinel() {
  if (expandedSentinelId.value) {
    setProfile(expandedSentinelId.value, 'LOW')
  }
  expandedSentinelId.value = null
  expandedSentinelName.value = ''
}
</script>

<template>
  <div class="proctor-view">
    <div v-if="!testId" class="no-test-selected">
      <p>No test has been selected.</p>
      <p class="hint">Select a test from the test details view to start proctoring.</p>
    </div>
    <template v-else>
      <div class="proctor-header">
        <h2>Proctoring Test: {{ testId }}</h2>
      </div>
      <div class="frame-grid">
        <div
v-for="sentinel in pagedSentinels" :key="sentinel.sentinelId" class="frame-card"
          @click="openSentinel(sentinel.sentinelId, sentinel.name)">
          <img
v-if="framesBySentinel[sentinel.sentinelId]"
            :src="'data:image/jpeg;base64,' + framesBySentinel[sentinel.sentinelId]"
            :alt="`Sentinel ${sentinel.name} frame`" />
          <div v-else class="frame-placeholder">Waiting for frame</div>
          <p class="frame-label">{{ sentinel.name }}</p>
        </div>
      </div>
      <div class="pager">
        <button :disabled="currentPage === 0" @click="currentPage--">Previous</button>
        <span class="pager-info">Page {{ currentPage + 1 }} / {{ totalPages }}</span>
        <button :disabled="currentPage >= totalPages - 1" @click="currentPage++">Next</button>
      </div>

      <div v-if="expandedSentinelId" class="overlay" @click.self="closeSentinel">
        <div class="overlay-content">
          <button class="overlay-close" @click="closeSentinel">&times;</button>
          <img
v-if="framesBySentinel[expandedSentinelId]"
            :src="'data:image/jpeg;base64,' + framesBySentinel[expandedSentinelId]"
            :alt="`Sentinel ${expandedSentinelName} frame`" />
          <div v-else class="frame-placeholder">Waiting for frame</div>
          <p class="overlay-label">{{ expandedSentinelName }}</p>
        </div>
      </div>
    </template>
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
  background: var(--bg-card);
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.08);
  padding: 0.35rem;
  gap: 0.35rem;
  width: 100%;
  cursor: pointer;
}

.frame-card:hover {
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.16);
}

.frame-card img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  display: block;
  border-radius: 4px;
  background: var(--bg-card);
}

.frame-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  padding: 0.75rem 0.5rem;
  border-radius: 4px;
  background: var(--bg-card);
  width: 100%;
  aspect-ratio: 16 / 9;
}

.frame-label {
  padding: 0.15rem 0;
  font-size: 0.95rem;
  text-align: center;
  word-break: break-all;
  font-family:
    ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New',
    monospace;
}

.frame-empty {}

.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.overlay-content {
  position: relative;
  background: var(--bg-card);
  border-radius: 8px;
  padding: 1rem;
  width: 80vw;
  height: 80vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.overlay-content img {
  width: 100%;
  height: 100%;
  border-radius: 4px;
  object-fit: contain;
  flex: 1;
  min-height: 0;
}

.overlay-close {
  position: absolute;
  top: 0.25rem;
  right: 0.5rem;
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  line-height: 1;
  color: var(--color);
}

.overlay-label {
  font-size: 1.1rem;
  text-align: center;
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
  transition:
    background-color 0.15s,
    border-color 0.15s;
}

.pager button:disabled {
  cursor: not-allowed;
}

.pager-info {
  font-size: 0.9rem;
}

.no-test-selected {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  min-height: 50vh;
  color: var(--text-secondary);
  text-align: center;
}

.no-test-selected p {
  margin: 0;
  font-size: 1.1rem;
}

.no-test-selected .hint {
  font-size: 0.9rem;
  color: var(--text-tertiary);
}

.proctor-header {
  margin-bottom: 1rem;
}

.proctor-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 500;
  color: var(--text-primary);
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
