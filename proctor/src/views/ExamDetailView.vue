<script setup lang="ts">
import Button from '@/components/ui/Button.vue'
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import {
  useExam,
  useUpdateExamSchedule,
  useDeleteExam,
  useStartExam,
  useEndExam,
} from '@/services/exams'
import { useExamSessions } from '@/services/sessions'
import type { Exam } from '@/types/Exam'
import type { ExamSession } from '@/services/sessions'

const route = useRoute()
const router = useRouter()
const { t, d } = useI18n()

const examId = route.params.id as string

const { data: examData } = useExam(examId)
const { data: sessionsData } = useExamSessions(examId)
const sessions = computed<ExamSession[]>(() => sessionsData.value ?? [])

const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editForm = ref({
  date: '',
  startTime: '',
  endTime: '',
})

const examStatus = computed(() => {
  if (!examData.value?.startedAt) return 'scheduled'
  if (!examData.value?.endedAt) return 'live'
  return 'completed'
})

const examStatusTranslated = computed(() => {
  if (examStatus.value === 'scheduled') return t('exams.scheduled')
  if (examStatus.value === 'live') return t('exams.live')
  return t('exams.completed')
})

const sessionList = computed(() => {
  const sentinelCounts: Record<string, number> = {}
  return sessions.value.map((s) => {
    const prevCount = sentinelCounts[s.sentinelId] ?? 0
    sentinelCounts[s.sentinelId] = prevCount + 1
    const name = s.user
      ? [s.user.givenName, s.user.familyName].filter(Boolean).join(' ') || s.user.preferredUsername
      : s.studentId.slice(0, 8)
    return {
      ...s,
      displayName: prevCount === 0 ? name : `${name} (${prevCount})`,
    }
  })
})

function openEditModal() {
  if (!examData.value) return

  const startDate = examData.value.startTime
  const endDate = examData.value.endTime

  editForm.value = {
    date: formatDateLocal(startDate),
    startTime: formatTime(startDate),
    endTime: formatTime(endDate),
  }
  showEditModal.value = true
}

function formatDateLocal(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function formatTime(date: Date) {
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
}

const { mutateAsync: updateExamSchedule } = useUpdateExamSchedule()

function saveEdit() {
  if (!examData.value || !editForm.value.date) return

  const [startHours = 0, startMinutes = 0] = editForm.value.startTime.split(':').map(Number)
  const [endHours = 0, endMinutes = 0] = editForm.value.endTime.split(':').map(Number)

  const dateParts = editForm.value.date.split('-').map(Number)
  const year = dateParts[0] ?? 0
  const month = (dateParts[1] ?? 1) - 1
  const day = dateParts[2] ?? 1

  const startDate = new Date(year, month, day, startHours, startMinutes, 0, 0)
  const endDate = new Date(year, month, day, endHours, endMinutes, 0, 0)

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
    })
}

async function deleteExam() {
  showDeleteModal.value = true
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

function getExamTime(exam: Exam | null | undefined): string {
  if (!exam) return ''
  const start = exam.startTime
  const end = exam.endTime
  return d(start, 'short') + ' · ' + d(start, 'time') + ' – ' + d(end, 'time')
}

async function copyUuid() {
  if (examData.value?.id) {
    await navigator.clipboard.writeText(examData.value.id)
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
          @click="router.push('/exams')"
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
        <span class="status-pill" v-if="examStatus === 'live'">
          <span class="status-dot"></span>
          {{ t('exams.live') }}
        </span>
        <span class="status-pill completed" v-if="examStatus === 'completed'">
          {{ t('exams.completed') }}
        </span>
        <span class="status-pill scheduled" v-if="examStatus === 'scheduled'">
          {{ t('exams.scheduled') }}
        </span>
      </div>
      <div class="header-meta">
        <span class="meta-item">PIN {{ examData.pin }}</span>
        <span class="meta-divider">·</span>
        <span class="meta-item">{{ getExamTime(examData) }}</span>
        <span class="meta-divider">·</span>
        <i
          class="bi bi-clipboard meta-item copy-btn"
          @click="copyUuid"
          :title="t('detail.copy_uuid')"
        ></i>
      </div>
    </header>

    <div class="dashboard-layout">
      <!-- Left: Students -->
      <div class="sessions-card">
        <h3>{{ t('detail.students') }}</h3>
        <div class="session-list">
          <div v-for="session in sessionList" :key="session.studentId" class="session-row">
            <span class="session-name">{{ session.displayName }}</span>
            <Button variant="secondary" disabled>{{ t('detail.download') }}</Button>
          </div>
        </div>
      </div>

      <!-- Right: Details + Actions -->
      <div class="right-panel">
        <div class="info-card">
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
            <span class="info-value status-badge" :class="examStatus">{{
              examStatusTranslated
            }}</span>
          </div>
        </div>

        <div class="actions-card">
          <h3>{{ t('detail.actions') }}</h3>
          <div class="action-buttons">
            <Button variant="secondary" @click="router.push(`/proctoring/${examId}`)">
              {{ t('detail.proctoring') }}
            </Button>
            <Button variant="secondary" disabled>{{ t('detail.download_all') }}</Button>
            <Button variant="secondary" @click="openEditModal">{{ t('detail.edit') }}</Button>
            <Button v-if="examStatus === 'scheduled'" variant="primary" @click="startExam">
              {{ t('detail.start') }}
            </Button>
            <Button v-if="examStatus === 'live'" variant="primary" @click="endExam">{{
              t('detail.end')
            }}</Button>
            <Button variant="danger" @click="deleteExam">{{ t('detail.delete') }}</Button>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Modal -->
    <div class="modal-overlay" v-if="showEditModal" @click.self="showEditModal = false">
      <div class="modal">
        <h2>{{ t('detail.edit_exam') }}</h2>
        <div class="form-group">
          <label>{{ t('exams.wizard.date') }}</label>
          <input type="date" v-model="editForm.date" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>{{ t('exams.wizard.start_time') }}</label>
            <input type="time" v-model="editForm.startTime" />
          </div>
          <div class="form-group">
            <label>{{ t('exams.wizard.end_time') }}</label>
            <input type="time" v-model="editForm.endTime" />
          </div>
        </div>
        <div class="modal-actions">
          <Button variant="secondary" @click="showEditModal = false">{{
            t('exams.wizard.cancel')
          }}</Button>
          <Button variant="primary" @click="saveEdit">{{ t('detail.save') }}</Button>
        </div>
      </div>
    </div>

    <!-- Delete Modal -->
    <div class="modal-overlay" v-if="showDeleteModal" @click.self="showDeleteModal = false">
      <div class="modal">
        <h2>{{ t('detail.delete_exam') }}</h2>
        <p class="delete-message">
          {{ t('detail.delete_confirmation') }}
        </p>
        <div class="modal-actions">
          <Button variant="secondary" @click="showDeleteModal = false">{{
            t('exams.wizard.cancel')
          }}</Button>
          <Button variant="danger" @click="confirmDelete">{{ t('detail.delete') }}</Button>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="view-management loading-state">
    <p>{{ t('detail.loading') }}</p>
  </div>
</template>

<style scoped>
.view-management {
  padding: 32px 40px;
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
}

.top-bar {
  margin-bottom: 32px;
}

.header-main {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.back-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: var(--bg-subtle);
  padding: 0;
  border-radius: 6px;
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

.status-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.75rem;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 100px;
  background: var(--status-live);
  color: white;
}

.status-pill.completed {
  background: var(--status-completed);
  color: white;
}

.status-pill.scheduled {
  background: var(--status-scheduled);
  color: white;
}

.status-dot {
  width: 6px;
  height: 6px;
  background: white;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(255, 255, 255, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0);
  }
}

.header-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.875rem;
  color: var(--text-secondary);
}

.meta-item {
  display: flex;
}

.meta-divider {
  color: var(--text-tertiary);
}

.copy-btn {
  cursor: pointer;
  transition: color 0.15s;
}

.copy-btn:hover {
  color: var(--primary);
}
.dashboard-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 20px;
  align-items: start;
}
/* Sessions Card */
.sessions-card {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 20px;
}
.sessions-card h3,
.info-card h3,
.actions-card h3 {
  margin: 0 0 16px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
}
.session-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.session-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  border: 1px solid var(--border-default);
  border-radius: 8px;
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
  gap: 16px;
}
.info-card,
.actions-card {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 20px;
}
.info-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
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
  gap: 2px;
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

.info-value.status-badge {
  text-transform: capitalize;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}

.info-value.status-badge.scheduled {
  background: var(--status-scheduled);
  color: white;
}

.info-value.status-badge.live {
  background: var(--status-live);
  color: white;
}

.info-value.status-badge.completed {
  background: var(--status-completed);
  color: white;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.action-buttons :deep(button) {
  width: 100%;
  justify-content: center;
}
.loading-state {
  text-align: center;
  color: var(--text-secondary);
  font-size: 1rem;
  margin-top: 50px;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
}

.modal {
  background: var(--bg-body);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 24px;
  width: 400px;
  max-width: 90vw;
}

.modal h2 {
  margin: 0 0 20px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: 6px;
}

.form-group input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--border-default);
  border-radius: 6px;
  font-size: 0.875rem;
  background: var(--bg-subtle);
  color: var(--text-primary);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  margin-top: 20px;
}

.delete-message {
  color: var(--text-secondary);
  font-size: 0.875rem;
  margin: 0 0 20px;
  line-height: 1.5;
}
</style>
