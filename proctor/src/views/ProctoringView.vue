<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import UiButton from '@/components/ui/Button.vue'
import ExpandedSentinelOverlay from '@/components/ExpandedSentinelOverlay.vue'
import { storeToRefs } from 'pinia'
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useExam } from '@/services/exams'

defineOptions({
  name: 'ProctoringView',
})

const route = useRoute()
const store = useWebsocketStore()
const { currentPage, totalPages, pagedSentinels, framesBySentinel } = storeToRefs(store)
const { setProfile, setPin, connect, disconnect, prevPage, nextPage } = store
const { t } = useI18n()

const examId = computed(() => route.params.id as string | undefined)

const { data: examData } = useExam(() => examId.value ?? '')

const examPin = computed(() => examData.value?.pin ?? null)
const examTitle = computed(() => examData.value?.title ?? '')

const expandedSentinelId = ref<string | null>(null)
const expandedSentinelName = ref<string>('')

const showOverlay = computed({
  get: () => expandedSentinelId.value !== null,
  set: (val) => {
    if (!val) {
      closeSentinel()
    }
  },
})

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

// Disconnect onBeforeUnmount to avoid socket state leaks during component teardown
onBeforeUnmount(() => {
  void disconnect()
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
        <Button as="router-link" :to="`/exams/${examId}`" variant="secondary" icon="bi-arrow-left">
          {{ t('proctoring.back_exam') }}
        </Button>
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
        <UiButton variant="secondary" :disabled="currentPage === 0" @click="prevPage()">{{
          t('proctoring.previous')
        }}</UiButton>
        <span class="pager-info"
          >{{ t('proctoring.page') }} {{ currentPage + 1 }} / {{ totalPages }}</span
        >
        <UiButton
          variant="secondary"
          :disabled="currentPage >= totalPages - 1"
          @click="nextPage()"
          >{{ t('proctoring.next') }}</UiButton
        >
      </div>

      <ExpandedSentinelOverlay
        v-model:open="showOverlay"
        :sentinel-name="expandedSentinelName"
        :frame-data="expandedSentinelId ? framesBySentinel[expandedSentinelId] : null"
      />
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
  border-radius: var(--radius-md);
  background: var(--bg-card);
  box-shadow: var(--shadow-card);
  border: 1px solid var(--border-default);
  padding: 0.35rem;
  gap: 0.35rem;
  width: 100%;
  cursor: pointer;
}

.frame-card:hover {
  border-color: var(--border-strong);
}

.frame-card img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  display: block;
  border-radius: var(--radius-sm);
  background: var(--bg-card);
}

.frame-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  padding: 0.75rem 0.5rem;
  border-radius: var(--radius-sm);
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

.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-3);
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
  gap: var(--space-2);
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
  display: flex;
  align-items: center;
  gap: 1rem;
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
