<script setup lang="ts">
import UiButton from '@/components/ui/Button.vue'
import UiCard from '@/components/ui/Card.vue'
import UiBadge from '@/components/ui/Badge.vue'
import { ref, computed, watch, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import {
  useExam,
  useUpdateExamSchedule,
  useDeleteExam,
  useStartExam,
  useEndExam,
} from '@/services/exams'
import { useExamSessions, useGenerateSentinelVideo } from '@/services/sessions'
import type { ExamSession } from '@/services/sessions'
import NewExamDialog from '@/components/NewExamDialog.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import { getExamStatus, examStatusTranslated } from '@/lib/examStatus'
import { formatExamRange, toDate, formatTime } from '@/lib/datetime'
import { downloadSentinelVideo } from '@/lib/videoDownload'

defineOptions({
  name: 'ExamDetailView',
})

const route = useRoute()
const router = useRouter()
const { t, d } = useI18n()

const examId = route.params.id as string

const { data: examData } = useExam(examId)
const sessionsQuery = useExamSessions(examId)
const sessions = computed<ExamSession[]>(() => sessionsQuery.data.value ?? [])
const generateVideoMutation = useGenerateSentinelVideo(examId)

const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editError = ref('')

// sentinelIds that the user triggered download for (awaiting DONE)
const pendingDownloads = ref(new Set<string>())

watch(showEditModal, (newVal) => {
  if (newVal) {
    editError.value = ''
  }
})

const hasPendingVideos = computed(() =>
  sessions.value.some((s) => s.videoStatus === 'PENDING'),
)

// Poll while any video is PENDING
let pollInterval: ReturnType<typeof setInterval> | null = null

function startPolling() {
  if (pollInterval) return
  pollInterval = setInterval(() => sessionsQuery.refetch(), 2000)
}

function stopPolling() {
  if (pollInterval) {
    clearInterval(pollInterval)
    pollInterval = null
  }
}

watch(hasPendingVideos, (pending) => {
  if (pending) startPolling()
  else stopPolling()
})

// Auto-download when DONE and pendingDownload was set
watch(sessions, (next) => {
  for (const s of next) {
    if (s.videoStatus === 'DONE' && pendingDownloads.value.has(s.sentinelId)) {
      pendingDownloads.value.delete(s.sentinelId)
      void downloadSentinelVideo(s.sentinelId, buildFilename(s.sentinelId))
    }
  }
})

onBeforeUnmount(stopPolling)

const examStatus = computed(() => {
  if (!examData.value) return 'scheduled'
  return getExamStatus(examData.value.startedAt, examData.value.endedAt)
})

const examStatusText = computed(() => {
  return examStatusTranslated(examStatus.value)
})

// sentinelId is UUID v7 (time-sortable) — sort ascending = chronological order
const sessionsSortedBySentinel = computed(() =>
  [...sessions.value].sort((a, b) => a.sentinelId.localeCompare(b.sentinelId)),
)

// Maps sentinelId → per-student session index (0 = first, 1 = second, …)
const sessionIndexMap = computed(() => {
  const studentCount: Record<string, number> = {}
  const map: Record<string, number> = {}
  for (const s of sessionsSortedBySentinel.value) {
    const count = studentCount[s.studentId] ?? 0
    map[s.sentinelId] = count
    studentCount[s.studentId] = count + 1
  }
  return map
})

const sessionList = computed(() =>
  sessionsSortedBySentinel.value.map((s) => {
    const idx = sessionIndexMap.value[s.sentinelId] ?? 0
    const name = s.user
      ? [s.user.givenName, s.user.familyName].filter(Boolean).join(' ') || s.user.preferredUsername
      : s.studentId.slice(0, 8)
    return {
      ...s,
      displayName: idx === 0 ? name : `${name} (${idx})`,
    }
  }),
)

function buildFilename(sentinelId: string): string {
  const s = sessions.value.find((x) => x.sentinelId === sentinelId)
  const lastName = s?.user?.familyName ?? ''
  const firstName = s?.user?.givenName ?? ''
  const exam = (examData.value?.title ?? sentinelId)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
  const baseName =
    ([lastName, firstName].filter(Boolean).join('_') || s?.user?.preferredUsername) ??
    sentinelId
  const idx = sessionIndexMap.value[sentinelId] ?? 0
  const namePart = idx === 0 ? baseName : `${baseName}_(${idx})`
  return `${namePart}_${exam}.mp4`
}

async function handleDownload(sentinelId: string) {
  if (examStatus.value !== 'completed') return
  const session = sessions.value.find((s) => s.sentinelId === sentinelId)
  if (!session) return

  if (session.videoStatus === 'PENDING') return

  if (session.videoStatus === 'DONE') {
    await downloadSentinelVideo(sentinelId, buildFilename(sentinelId))
    return
  }

  // null or FAILED — trigger generation
  try {
    await generateVideoMutation.mutateAsync(sentinelId)
    pendingDownloads.value.add(sentinelId)
  } catch (e) {
    console.error('Failed to generate video', sentinelId, e)
  }
}

async function downloadAll() {
  if (examStatus.value !== 'completed') return

  const done = sessions.value.filter((s) => s.videoStatus === 'DONE')
  const toGenerate = sessions.value.filter((s) => s.videoStatus === null || s.videoStatus === 'FAILED')

  for (const s of done) {
    await downloadSentinelVideo(s.sentinelId, buildFilename(s.sentinelId))
  }

  for (const s of toGenerate) {
    try {
      await generateVideoMutation.mutateAsync(s.sentinelId)
      pendingDownloads.value.add(s.sentinelId)
    } catch (e) {
      console.error('generate failed', s.sentinelId, e)
    }
    await new Promise((resolve) => setTimeout(resolve, 1000))
  }
}

const editFormValues = computed(() => {
  if (!examData.value) {
    return {
      title: '',
      date: '',
      startTime: '',
      endTime: '',
    }
  }
  const startDate = toDate(examData.value.startTime) ?? new Date()
  const endDate = toDate(examData.value.endTime) ?? new Date()

  // Format date as YYYY-MM-DD
  const year = startDate.getFullYear()
  const month = String(startDate.getMonth() + 1).padStart(2, '0')
  const day = String(startDate.getDate()).padStart(2, '0')

  return {
    title: examData.value.title,
    date: `${year}-${month}-${day}`,
    startTime: formatTime(startDate),
    endTime: formatTime(endDate),
  }
})

const { mutateAsync: updateExamSchedule } = useUpdateExamSchedule()

function saveEdit(payload: { date: string; startTime: string; endTime: string }) {
  editError.value = ''
  const [startHours = 0, startMinutes = 0] = payload.startTime.split(':').map(Number)
  const [endHours = 0, endMinutes = 0] = payload.endTime.split(':').map(Number)

  const dateParts = payload.date.split('-').map(Number)
  const year = dateParts[0] ?? 0
  const month = (dateParts[1] ?? 1) - 1
  const day = dateParts[2] ?? 1

  if (!year || isNaN(year) || isNaN(month) || isNaN(day)) {
    editError.value = t('exams.errors.invalid_date_format')
    return
  }

  const startDate = new Date(year, month, day, startHours, startMinutes, 0, 0)
  const endDate = new Date(year, month, day, endHours, endMinutes, 0, 0)

  if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
    editError.value = t('exams.errors.invalid_date_values')
    return
  }

  if (endDate <= startDate) {
    editError.value = t('exams.errors.end_after_start')
    return
  }

  updateExamSchedule({
    examId,
    startTime: startDate,
    endTime: endDate,
  })
    .then(() => {
      showEditModal.value = false
    })
    .catch((e) => {
      console.error('Failed to update exam', e)
      editError.value = t('exams.errors.update_failed')
    })
}

const { mutateAsync: deleteExamMutation } = useDeleteExam()

async function confirmDelete() {
  await deleteExamMutation(examId)
  showDeleteModal.value = false
  await router.push('/')
}

const { mutateAsync: startExamMutation } = useStartExam()

async function startExam() {
  await startExamMutation(examId)
}

const { mutateAsync: endExamMutation } = useEndExam()

async function endExam() {
  await endExamMutation(examId)
}

const copied = ref(false)

async function copyUuid() {
  if (examData.value?.id) {
    await navigator.clipboard.writeText(examData.value.id)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 2000)
  }
}
</script>

<template>
  <div class="view-management" v-if="examData">
    <header class="top-bar">
      <div class="header-main">
        <button
          class="back-btn"
          :aria-label="t('detail.back_exams')"
          @click="router.back()"
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <path d="M19 12H5M12 19l-7-7 7-7" />
          </svg>
        </button>
        <h1>{{ examData.title }}</h1>
        <UiBadge :variant="examStatus">{{ examStatusText }}</UiBadge>
      </div>
      <div class="header-meta">
        <span class="meta-item">PIN {{ examData.pin }}</span>
        <span class="meta-divider">·</span>
        <span class="meta-item">{{ formatExamRange(examData.startTime, examData.endTime) }}</span>
        <span class="meta-divider">·</span>
        <i
          class="bi meta-item copy-btn"
          :class="[copied ? 'bi-clipboard-check copied' : 'bi-clipboard']"
          tabindex="0"
          role="button"
          :aria-label="t('detail.copy_uuid')"
          :title="copied ? t('detail.copied') : t('detail.copy_uuid')"
          @click="copyUuid"
          @keydown.enter.prevent="copyUuid"
          @keydown.space.prevent="copyUuid"
        ></i>
      </div>
    </header>

    <div class="dashboard-layout">
      <!-- Left: Students -->
      <UiCard class="sessions-card">
        <h3>{{ t('detail.students') }}</h3>
        <p v-if="examStatus !== 'completed'" class="download-notice">
          <i class="bi bi-info-circle"></i>
          {{ t('detail.download_after_exam') }}
        </p>
        <div class="session-list">
          <div v-for="session in sessionList" :key="session.studentId" class="session-row">
            <span class="session-name">{{ session.displayName }}</span>
            <UiButton
              variant="secondary"
              :class="{
                'btn-not-generated': !session.videoStatus || session.videoStatus === 'FAILED',
                'btn-generated': session.videoStatus === 'DONE',
              }"
              :disabled="examStatus !== 'completed' || session.videoStatus === 'PENDING'"
              :title="examStatus !== 'completed' ? t('detail.download_after_exam') : undefined"
              @click="handleDownload(session.sentinelId)"
            >
              <span v-if="session.videoStatus === 'PENDING'" class="spinner"></span>
              {{
                session.videoStatus === 'DONE'
                  ? t('detail.download')
                  : t('detail.generate')
              }}
            </UiButton>
          </div>
        </div>
      </UiCard>

      <!-- Right: Details + Actions -->
      <div class="right-panel">
        <UiCard class="info-card">
          <h3>{{ t('detail.details') }}</h3>
          <div class="info-row row-start">
            <span class="info-label">{{ t('exams.wizard.start_time') }}</span>
            <div class="info-dates">
              <span class="date-scheduled">
                {{ t('detail.scheduled') }}:
                {{
                  examData.startTime ? d(new Date(examData.startTime), 'long') : t('common.not_set')
                }}
              </span>
              <span class="date-actual">
                {{ t('detail.actual_start') }}:
                {{ examData.startedAt ? d(new Date(examData.startedAt), 'long') : '—' }}
              </span>
            </div>
          </div>
          <div class="info-row row-end">
            <span class="info-label">{{ t('exams.wizard.end_time') }}</span>
            <div class="info-dates">
              <span class="date-scheduled">
                {{ t('detail.scheduled') }}:
                {{ examData.endTime ? d(new Date(examData.endTime), 'long') : t('common.not_set') }}
              </span>
              <span class="date-actual">
                {{ t('detail.actual_end') }}:
                {{ examData.endedAt ? d(new Date(examData.endedAt), 'long') : '—' }}
              </span>
            </div>
          </div>
          <div class="info-row">
            <span class="info-label">{{ t('detail.status') }}</span>
            <UiBadge :variant="examStatus">{{ examStatusText }}</UiBadge>
          </div>
        </UiCard>

        <UiCard class="actions-card">
          <h3>{{ t('detail.actions') }}</h3>
          <div class="action-buttons">
            <UiButton block variant="secondary" @click="router.push(`/proctoring/${examId}`)">
              {{ t('detail.proctoring') }}
            </UiButton>
            <UiButton
              block
              variant="secondary"
              :disabled="examStatus !== 'completed'"
              :title="examStatus !== 'completed' ? t('detail.download_after_exam') : undefined"
              @click="downloadAll"
            >
              {{ t('detail.download_all') }}
            </UiButton>
            <UiButton block variant="secondary" @click="showEditModal = true">{{
              t('detail.edit')
            }}</UiButton>
            <UiButton v-if="examStatus === 'scheduled'" block variant="primary" @click="startExam">
              {{ t('detail.start') }}
            </UiButton>
            <UiButton v-if="examStatus === 'live'" block variant="primary" @click="endExam">{{
              t('detail.end')
            }}</UiButton>
            <UiButton block variant="danger" @click="showDeleteModal = true">{{
              t('detail.delete')
            }}</UiButton>
          </div>
        </UiCard>
      </div>
    </div>

    <!-- Edit Modal -->
    <NewExamDialog
      v-model:open="showEditModal"
      is-edit
      :initial-values="editFormValues"
      :error="editError"
      @submit="saveEdit"
    />

    <!-- Delete Modal -->
    <ConfirmDialog
      v-model:open="showDeleteModal"
      variant="danger"
      :title="t('detail.delete_exam')"
      :description="t('detail.delete_confirmation')"
      :confirm-label="t('detail.delete')"
      :cancel-label="t('exams.wizard.cancel')"
      @confirm="confirmDelete"
    />
  </div>
  <div v-else class="view-management loading-state">
    <p>{{ t('detail.loading') }}</p>
  </div>
</template>

<style scoped>
.view-management {
  padding: var(--space-8) var(--space-10);
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
}

.top-bar {
  margin-bottom: var(--space-8);
}

.header-main {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-2);
}

.back-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: var(--space-8);
  height: var(--space-8);
  border: none;
  background: var(--bg-subtle);
  padding: 0;
  border-radius: var(--radius-md);
  color: var(--text-secondary);
  cursor: pointer;
  transition: background 0.15s;
}
.back-btn:hover {
  background: var(--border-default);
  color: var(--text-primary);
}

h1 {
  font-size: 1.25rem;
  font-weight: 500;
  color: var(--text-primary);
  letter-spacing: -0.01em;
}

.copy-btn {
  cursor: pointer;
  transition: color 0.15s;
}

.copy-btn:hover {
  color: var(--primary);
}

.copy-btn.copied {
  color: var(--success);
}
.dashboard-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: var(--space-5);
  align-items: start;
}
/* Sessions Card */
.sessions-card h3,
.info-card h3,
.actions-card h3 {
  margin: 0 0 var(--space-4);
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
}
.session-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.session-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  background: var(--bg-subtle);
}
.session-name {
  font-size: 0.9rem;
  color: var(--text-primary);
  font-weight: 500;
}
/* Right Panel */
.right-panel {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}
.info-row {
  display: flex;
  justify-content: space-between;
  padding: var(--space-2) 0;
  border-bottom: 1px solid var(--border-default);
}

.info-row:last-child {
  border-bottom: none;
}

.info-row.row-start,
.info-row.row-end {
  align-items: flex-start;
}

.info-dates {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  text-align: right;
}

.date-scheduled,
.date-actual {
  font-size: 0.8rem;
}

.date-scheduled {
  color: var(--text-primary);
}

.date-actual {
  color: var(--text-secondary);
  font-size: 0.75rem;
}

.info-label {
  color: var(--text-secondary);
  font-size: 0.875rem;
}

.info-value {
  color: var(--text-primary);
  font-size: 0.875rem;
  font-weight: 500;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.loading-state {
  text-align: center;
  color: var(--text-secondary);
  font-size: 1rem;
  margin-top: var(--space-12);
}

.btn-generated {
  border-color: var(--primary) !important;
  color: var(--primary) !important;
}

.download-notice {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--warning);
  background: var(--alert-warning-bg);
  border: 1px solid var(--warning);
  border-radius: 8px;
  padding: 10px 14px;
  margin: 0 0 16px;
}

.spinner {
  display: inline-block;
  width: 12px;
  height: 12px;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  flex-shrink: 0;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
