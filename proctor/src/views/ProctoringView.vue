<script setup lang="ts">
import { useWebsocketStore } from '@/stores/WebsocketStore.ts'
import UiButton from '@/components/ui/Button.vue'
import UiCard from '@/components/ui/Card.vue'
import ExpandedSentinelOverlay from '@/components/ExpandedSentinelOverlay.vue'
import { storeToRefs } from 'pinia'
import { ref, computed, onBeforeUnmount, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useExam } from '@/services/exams'
import { useExamEvents } from '@/services/examEvents'
import { TabsContent, TabsList, TabsRoot, TabsTrigger } from 'reka-ui'

defineOptions({
  name: 'ProctoringView',
})

const route = useRoute()
const store = useWebsocketStore()
const { currentPage, totalPages, pagedSentinels, framesBySentinel } = storeToRefs(store)
const { setProfile, setExamFilter, prevPage, nextPage } = store
const { t, d } = useI18n()

const examId = computed(() => route.params.id as string | undefined)

const { data: examData } = useExam(() => examId.value ?? '')
const { students, sentinelIds, events, currentStudentCount, peakStudentCount } = useExamEvents(
  () => examId.value ?? '',
)

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

watch(
  sentinelIds,
  (ids) => {
    setExamFilter(ids)
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

onBeforeUnmount(() => {
  setExamFilter(null)
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
        <UiButton
          as="router-link"
          :to="`/exams/${examId}`"
          variant="secondary"
          icon="bi-arrow-left"
        >
          {{ t('proctoring.back_exam') }}
        </UiButton>
        <span class="student-count" :class="{ dropped: currentStudentCount < peakStudentCount }">
          {{ t('proctoring.students') }}: {{ currentStudentCount }}/{{ peakStudentCount }}
        </span>
      </div>
      <div class="proctor-body">
        <div class="proctor-main">
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
        </div>
        <UiCard class="event-log">
          <TabsRoot default-value="events">
            <TabsList class="event-tabs">
              <TabsTrigger value="events" class="event-tab">{{
                t('proctoring.events')
              }}</TabsTrigger>
              <TabsTrigger value="students" class="event-tab">{{
                t('proctoring.students')
              }}</TabsTrigger>
            </TabsList>
            <TabsContent value="events">
              <p v-if="events.length === 0" class="hint">{{ t('proctoring.no_events') }}</p>
              <ul v-else>
                <li v-for="event in events" :key="event.id" :class="event.type">
                  <span class="event-time"
                    >{{ event.exact ? '' : '≈' }}{{ d(event.time, 'time') }}</span
                  >
                  {{ event.name }}
                  {{ event.type === 'join' ? t('proctoring.joined') : t('proctoring.left') }}
                </li>
              </ul>
            </TabsContent>
            <TabsContent value="students">
              <p v-if="students.length === 0" class="hint">{{ t('proctoring.no_students') }}</p>
              <ul v-else>
                <li
                  v-for="student in students"
                  :key="student.studentId"
                  :class="{ leave: !student.present }"
                >
                  {{ student.name }}
                </li>
              </ul>
            </TabsContent>
          </TabsRoot>
        </UiCard>
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
.proctor-body {
  flex: 1;
  display: flex;
  gap: 1rem;
  min-height: 0;
}

.proctor-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.event-log {
  width: 20rem;
  overflow-y: auto;
}

.event-tabs {
  display: flex;
  gap: var(--space-1);
  margin-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-default);
}

.event-tab {
  flex: 1;
  padding: var(--space-2);
  border: none;
  border-bottom: 2px solid transparent;
  background: transparent;
  color: var(--text-secondary);
  font: inherit;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
}

.event-tab[data-state='active'] {
  color: var(--text-primary);
  border-bottom-color: var(--text-primary);
}

.event-log ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.event-log li {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  background: var(--bg-subtle);
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--text-primary);
}

.event-log li.join {
  color: var(--status-completed);
}

.event-log li.leave {
  color: var(--status-live);
  border-color: var(--status-live);
}

.event-log .event-time,
.event-log .hint {
  color: var(--text-tertiary);
  font-family: var(--font-mono);
}

.event-log .hint {
  margin: 0;
  font-size: 0.9rem;
}

.student-count {
  margin-left: auto;
  font-weight: 500;
}

.student-count.dropped {
  color: var(--status-live);
}

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

@media (max-width: 900px) {
  .proctor-body {
    flex-direction: column;
  }

  .event-log {
    width: auto;
    max-height: 12rem;
  }
}

@media (max-width: 600px) {
  .frame-grid {
    grid-template-columns: 1fr;
  }
}
</style>
