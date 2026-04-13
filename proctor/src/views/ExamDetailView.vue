<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const { client } = useApolloClientStore()
const route = useRoute()
const router = useRouter()

const examId = route.params.id as string

interface Student {
  id: string
  name: string
  status: 'CONNECTED' | 'IDLE' | 'DISCONNECTED'
}

interface Exam {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: string | null
  endTime: string | null
  startedAt: string | null
  endedAt: string | null
  students: Student[]
}

const examData = ref<Exam | null>(null)

const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editForm = ref({
  date: '',
  startTime: '',
  endTime: '',
})

const dummyStudents: Student[] = [
  { id: 'S2301', name: 'Lena Brandt', status: 'CONNECTED' },
  { id: 'S2302', name: 'Max Huber', status: 'CONNECTED' },
  { id: 'S2303', name: 'Sophie Maier', status: 'CONNECTED' },
  { id: 'S2304', name: 'Tim Fischer', status: 'CONNECTED' },
  { id: 'S2305', name: 'Anna Schneider', status: 'IDLE' },
  { id: 'S2306', name: 'Paul Wagner', status: 'DISCONNECTED' },
]

function fetchExam() {
  client
    .query<{ examId: Exam }>({
      query: gql`
        query GetExam($id: String!) {
          examId(id: $id) {
            id
            title
            pin
            teacherId
            startTime
            endTime
            startedAt
            endedAt
          }
        }
      `,
      variables: { id: examId },
      fetchPolicy: 'network-only',
    })
    .then((res) => {
      if (res.data?.examId) {
        examData.value = { ...res.data.examId, students: dummyStudents }
      }
    })
    .catch((e) => {
      console.error('Failed to fetch exam!', e)
    })
}

onMounted(() => {
  fetchExam()
})

const examStatus = computed(() => {
  if (!examData.value?.startedAt) return 'scheduled'
  if (!examData.value?.endedAt) return 'live'
  return 'completed'
})

function openEditModal() {
  if (!examData.value) return

  const startDate = examData.value.startTime ? new Date(examData.value.startTime) : null
  const endDate = examData.value.endTime ? new Date(examData.value.endTime) : null

  editForm.value = {
    date: startDate ? formatDateLocal(startDate) : '',
    startTime: startDate ? formatTime(startDate) : '',
    endTime: endDate ? formatTime(endDate) : '',
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
  return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}

function formatDateTime(dateStr: string | null) {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  })
}

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

  const tid = examId
  const tsi = {
    startTime: startDate.toISOString(),
    endTime: endDate.toISOString(),
  }

  client
    .mutate<{
      updateExamSchedule: { id: string; title: string; startTime: string; endTime: string } | null
    }>({
      mutation: gql`
        mutation UpdateExamSchedule($tid: String!, $tsi: UpdateExamScheduleInput!) {
          updateExamSchedule(examId: $tid, examScheduleInput: $tsi) {
            id
            title
            startTime
            endTime
          }
        }
      `,
      variables: { tid, tsi },
    })
    .then((res) => {
      if (res.data?.updateExamSchedule) {
        fetchExam()
        showEditModal.value = false
      }
    })
    .catch((e) => {
      console.error('Failed to update exam', e)
    })
}

async function deleteExam() {
  showDeleteModal.value = true
}

async function confirmDelete() {
  await client.mutate<{ deleteExam: boolean }>({
    mutation: gql`
      mutation DeleteExam($id: String!) {
        deleteExam(id: $id)
      }
    `,
    variables: { id: examId },
  })
  showDeleteModal.value = false
  await router.push('/')
}

async function startExam() {
  await client.mutate({
    mutation: gql`
      mutation StartExam($examId: String!) {
        startExam(examId: $examId) {
          id
          startedAt
        }
      }
    `,
    variables: { examId },
  })
  fetchExam()
}

async function endExam() {
  await client.mutate({
    mutation: gql`
      mutation EndExam($examId: String!) {
        endExam(examId: $examId) {
          id
          endedAt
        }
      }
    `,
    variables: { examId },
  })
  fetchExam()
}

function getExamTime(exam: Exam) {
  if (exam.startTime && exam.endTime) {
    const start = new Date(exam.startTime)
    const end = new Date(exam.endTime)
    return `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · ${formatTime(start)} – ${formatTime(end)}`
  }
  if (exam.startTime) {
    const start = new Date(exam.startTime)
    return `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · ${formatTime(start)} – now`
  }
  return 'Not scheduled'
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
        <button class="back-btn" @click="router.push('/exams')">
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
          Live
        </span>
        <span class="status-pill completed" v-if="examStatus === 'completed'"> Completed </span>
        <span class="status-pill scheduled" v-if="examStatus === 'scheduled'"> Scheduled </span>
      </div>
      <div class="header-meta">
        <span class="meta-item">PIN {{ examData.pin }}</span>
        <span class="meta-divider">·</span>
        <span class="meta-item">{{ getExamTime(examData) }}</span>
        <span class="meta-divider">·</span>
        <i class="bi bi-clipboard meta-item copy-btn" @click="copyUuid" title="Copy UUID"></i>
      </div>
    </header>

    <div class="dashboard-layout">
      <div class="info-card">
        <h3>Exam Details</h3>
        <div class="info-row row-start">
          <span class="info-label">Start</span>
          <div class="info-dates">
            <span class="date-scheduled"
              >Scheduled:
              {{ examData.startTime ? formatDateTime(examData.startTime) : 'Not set' }}</span
            >
            <span class="date-actual"
              >Actual: {{ examData.startedAt ? formatDateTime(examData.startedAt) : '—' }}</span
            >
          </div>
        </div>
        <div class="info-row row-end">
          <span class="info-label">End</span>
          <div class="info-dates">
            <span class="date-scheduled"
              >Scheduled:
              {{ examData.endTime ? formatDateTime(examData.endTime) : 'Not set' }}</span
            >
            <span class="date-actual"
              >Actual: {{ examData.endedAt ? formatDateTime(examData.endedAt) : '—' }}</span
            >
          </div>
        </div>
        <div class="info-row">
          <span class="info-label">Status</span>
          <span class="info-value status-badge" :class="examStatus">{{ examStatus }}</span>
        </div>
      </div>
    </div>

    <div class="actions-footer">
      <button class="btn-danger" @click="deleteExam">Delete</button>
      <button class="btn-secondary" @click="openEditModal">Edit</button>
      <button class="btn-secondary" @click="router.push(`/proctoring/${examId}`)">
        Proctoring
      </button>
      <button v-if="examStatus === 'scheduled'" class="btn-primary" @click="startExam">
        Start
      </button>
      <button v-if="examStatus === 'live'" class="btn-primary" @click="endExam">End</button>
    </div>

    <!-- Edit Modal -->
    <div class="modal-overlay" v-if="showEditModal" @click.self="showEditModal = false">
      <div class="modal">
        <h2>Edit Exam</h2>
        <div class="form-group">
          <label>Date</label>
          <input type="date" v-model="editForm.date" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Start Time</label>
            <input type="time" v-model="editForm.startTime" />
          </div>
          <div class="form-group">
            <label>End Time</label>
            <input type="time" v-model="editForm.endTime" />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn-secondary" @click="showEditModal = false">Cancel</button>
          <button class="btn-primary" @click="saveEdit">Save</button>
        </div>
      </div>
    </div>

    <!-- Delete Modal -->
    <div class="modal-overlay" v-if="showDeleteModal" @click.self="showDeleteModal = false">
      <div class="modal">
        <h2>Delete Exam</h2>
        <p class="delete-message">
          Are you sure you want to delete this exam? This action cannot be undone.
        </p>
        <div class="modal-actions">
          <button class="btn-secondary" @click="showDeleteModal = false">Cancel</button>
          <button class="btn-danger" @click="confirmDelete">Delete</button>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="view-management loading-state">
    <p>Loading exam details...</p>
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
  border-radius: 6px;
  cursor: pointer;
  color: var(--text-secondary);
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
  grid-template-columns: 1fr;
  gap: 20px;
}

.actual-times {
  margin-top: 4px;
}

.info-card {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 20px;
}

.info-card h3 {
  margin: 0 0 16px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
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

.actions-footer {
  margin-top: 24px;
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.btn-primary {
  background: var(--primary);
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.15s;
}
.btn-primary:hover {
  opacity: 0.9;
}
.btn-secondary {
  background: var(--bg-subtle);
  border: 1px solid var(--border-default);
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  color: var(--text-primary);
  transition: background 0.15s;
}
.btn-secondary:hover {
  background: var(--border-default);
}
.btn-danger {
  background: transparent;
  border: 1px solid var(--error);
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  color: var(--error);
  transition: background 0.15s;
}
.btn-danger:hover {
  background: var(--alert-error-bg);
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
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
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
