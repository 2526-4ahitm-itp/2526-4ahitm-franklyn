<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import Button from '@/components/ui/Button.vue'
import { storeToRefs } from 'pinia'
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useExam } from '@/services/exams'

const route = useRoute()
const store = useWebsocketStore()
const { currentPage, totalPages, pagedSentinels, framesBySentinel } = storeToRefs(store)
const { setProfile, setPin, connect, disconnect } = store
const { t } = useI18n()

const examId = computed(() => route.params.id as string | undefined)

const { data: examData } = useExam(() => examId.value ?? '')

const examPin = computed(() => examData.value?.pin ?? null)
const examTitle = computed(() => examData.value?.title ?? '')

const expandedSentinelId = ref<string | null>(null)
const expandedSentinelName = ref<string>('')

onMounted(() => {
  connect()
})

watch(
  () => examData.value?.pin,
  (pin) => {
    if (pin) {
      setPin(pin)
    }
  },
  { immediate: true },
)

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

onUnmounted(() => {
  disconnect()
})
</script>

<template>
  <div class="proctor-view">
    <div v-if="!examId" class="no-exam-selected">
      <p>{{ t('proctoring.no_selection') }}</p>
      <p class="hint">{{ t('proctoring.hint') }}</p>
    </div>
    <template v-else>
      <div class="proctor-header">
        <h2>
          {{ examTitle }} <span class="pin-badge">{{ examPin }}</span>
        </h2>
      </div>
      <div class="frame-grid">
        <div
          v-for="sentinel in pagedSentinels"
          :key="sentinel.sentinelId"
          class="frame-card"
          @click="openSentinel(sentinel.sentinelId, sentinel.name)"
        >
          <img
            v-if="framesBySentinel[sentinel.sentinelId]"
            :src="'data:image/jpeg;base64,' + framesBySentinel[sentinel.sentinelId]"
            :alt="`Sentinel ${sentinel.name} frame`"
          />
          <div v-else class="frame-placeholder">{{ t('proctoring.waiting') }}</div>
          <p class="frame-label">{{ sentinel.name }}</p>
        </div>
      </div>
      <div class="pager">
        <Button variant="secondary" :disabled="currentPage === 0" @click="currentPage--">{{
          t('proctoring.previous')
        }}</Button>
        <span class="pager-info"
          >{{ t('proctoring.page') }} {{ currentPage + 1 }} / {{ totalPages }}</span
        >
        <Button
          variant="secondary"
          :disabled="currentPage >= totalPages - 1"
          @click="currentPage++"
          >{{ t('proctoring.next') }}</Button
        >
      </div>

      <div v-if="expandedSentinelId" class="overlay" @click.self="closeSentinel">
        <div class="overlay-content">
          <Button
            class="overlay-close"
            variant="secondary"
            aria-label="Close expanded frame"
            @click="closeSentinel"
          >
            &times;
          </Button>
          <img
            v-if="framesBySentinel[expandedSentinelId]"
            :src="'data:image/jpeg;base64,' + framesBySentinel[expandedSentinelId]"
            :alt="`Sentinel ${expandedSentinelName} frame`"
          />
          <div v-else class="frame-placeholder">{{ t('proctoring.waiting') }}</div>
          <p class="overlay-label">{{ expandedSentinelName }}</p>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.proctor-view {
  min-height: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 1rem;
  box-sizing: border-box;
}

.frame-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.4rem 1rem;
  justify-items: center;
  align-items: start;
  align-content: center;
  min-height: 0;
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
  font-family: var(--font-mono);
}

.overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
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

.overlay-close.button {
  position: absolute;
  top: 0.25rem;
  right: 0.5rem;
  min-height: 0;
  min-width: 0;
  padding: 0.1rem 0.35rem;
  font-size: 1.5rem;
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

.pager .button {
  padding: 0.4rem 0.8rem;
  border-radius: 0;
  border: 1px solid currentColor;
  background-color: transparent;
  color: inherit;
  transition:
    background-color 0.15s,
    border-color 0.15s;
  min-height: 0;
}

.pager .button:disabled,
.pager .button.button--disabled {
  cursor: not-allowed;
}

.pager-info {
  font-size: 0.9rem;
}

.no-exam-selected {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  min-height: 50vh;
  color: var(--text-secondary);
  text-align: center;
}

.no-exam-selected p {
  margin: 0;
  font-size: 1.1rem;
}

.no-exam-selected .hint {
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
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.pin-badge {
  font-family: var(--font-mono);
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--text-secondary);
  background: var(--bg-subtle);
  padding: 0.25rem 0.5rem;
  border-radius: var(--radius-sm);
  letter-spacing: 0.05em;
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
