<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const { client } = useApolloClientStore()
const route = useRoute()
const router = useRouter()

const testId = route.params.id as string

interface Student {
  id: string
  name: string
  status: 'CONNECTED' | 'IDLE' | 'DISCONNECTED'
}

interface Test {
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

const testData = ref<Test | null>(null)

const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editForm = ref({
  date: '',
  startTime: '',
  endTime: ''
})

const dummyStudents: Student[] = [
  { id: 'S2301', name: 'Lena Brandt', status: 'CONNECTED' },
  { id: 'S2302', name: 'Max Huber', status: 'CONNECTED' },
  { id: 'S2303', name: 'Sophie Maier', status: 'CONNECTED' },
  { id: 'S2304', name: 'Tim Fischer', status: 'CONNECTED' },
  { id: 'S2305', name: 'Anna Schneider', status: 'IDLE' },
  { id: 'S2306', name: 'Paul Wagner', status: 'DISCONNECTED' }
]

function fetchTest() {
  client
    .query<{ testId: Test }>({
      query: gql`
        query GetTest($id: String!) {
          testId(id: $id) {
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
      variables: { id: testId },
      fetchPolicy: 'network-only'
    })
    .then((res) => {
      if (res.data?.testId) {
        testData.value = { ...res.data.testId, students: dummyStudents }
      }
    })
    .catch((e) => {
      console.error('Failed to fetch test!', e)
    })
}

onMounted(() => {
  fetchTest()
})

const testStatus = computed(() => {
  if (!testData.value?.startedAt) return 'scheduled'
  if (!testData.value?.endedAt) return 'live'
  return 'completed'
})

function openEditModal() {
  if (!testData.value) return

  const startDate = testData.value.startTime ? new Date(testData.value.startTime) : null
  const endDate = testData.value.endTime ? new Date(testData.value.endTime) : null

  editForm.value = {
    date: startDate ? formatDateLocal(startDate) : '',
    startTime: startDate ? formatTime(startDate) : '',
    endTime: endDate ? formatTime(endDate) : ''
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
    hour12: false 
  })
}

function saveEdit() {
  if (!testData.value || !editForm.value.date) return

  const [startHours = 0, startMinutes = 0] = editForm.value.startTime.split(':').map(Number)
  const [endHours = 0, endMinutes = 0] = editForm.value.endTime.split(':').map(Number)

  const dateParts = editForm.value.date.split('-').map(Number)
  const year = dateParts[0] ?? 0
  const month = (dateParts[1] ?? 1) - 1
  const day = dateParts[2] ?? 1

  const startDate = new Date(year, month, day, startHours, startMinutes, 0, 0)
  const endDate = new Date(year, month, day, endHours, endMinutes, 0, 0)

  const tid = testId
  const tsi = {
    startTime: startDate.toISOString(),
    endTime: endDate.toISOString()
  }
  
  client.mutate<{ updateTestSchedule: { id: string; title: string; startTime: string; endTime: string } | null }>({
    mutation: gql`
      mutation UpdateTestSchedule($tid: String!, $tsi: UpdateTestScheduleInput!) {
        updateTestSchedule(testId: $tid, testScheduleInput: $tsi) {
          id
          title
          startTime
          endTime
        }
      }
    `,
    variables: { tid, tsi }
  }).then((res) => {
    if (res.data?.updateTestSchedule) {
      fetchTest()
      showEditModal.value = false
    }
  }).catch(e => {
    console.error("Failed to update test", e)
  })
}

async function deleteTest() {
  showDeleteModal.value = true
}

async function confirmDelete() {
  await client.mutate<{ deleteTest: boolean }>({
    mutation: gql`
      mutation DeleteTest($id: String!) {
        deleteTest(id: $id)
      }
    `,
    variables: { id: testId }
  })
  showDeleteModal.value = false
  await router.push('/')
}

async function startTest() {
  await client.mutate({
    mutation: gql`
      mutation StartTest($testId: String!) {
        startTest(testId: $testId) {
          id
          startedAt
        }
      }
    `,
    variables: { testId }
  })
  fetchTest()
}

async function endTest() {
  await client.mutate({
    mutation: gql`
      mutation EndTest($testId: String!) {
        endTest(testId: $testId) {
          id
          endedAt
        }
      }
    `,
    variables: { testId }
  })
  fetchTest()
}

function getTestTime(test: Test) {
  if (test.startTime && test.endTime) {
    const start = new Date(test.startTime)
    const end = new Date(test.endTime)
    return `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · ${formatTime(start)} – ${formatTime(end)}`
  }
  if (test.startTime) {
    const start = new Date(test.startTime)
    return `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · ${formatTime(start)} – now`
  }
  return 'Not scheduled'
}

async function copyUuid() {
  if (testData.value?.id) {
    await navigator.clipboard.writeText(testData.value.id)
  }
}

</script>

<template>
  <div class="view-management" v-if="testData">
    <header class="top-bar">
      <div class="header-main">
        <button class="back-btn" @click="router.push('/tests')">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 12H5M12 19l-7-7 7-7"/>
          </svg>
        </button>
        <h1>{{ testData.title }}</h1>
        <span class="status-pill" v-if="testStatus === 'live'">
          <span class="status-dot"></span>
          Live
        </span>
        <span class="status-pill completed" v-if="testStatus === 'completed'">
          Completed
        </span>
        <span class="status-pill scheduled" v-if="testStatus === 'scheduled'">
          Scheduled
        </span>
      </div>
      <div class="header-meta">
        <span class="meta-item">PIN {{ testData.pin }}</span>
        <span class="meta-divider">·</span>
        <span class="meta-item">{{ getTestTime(testData) }}</span>
        <span class="meta-divider">·</span>
        <i class="bi bi-clipboard meta-item copy-btn" @click="copyUuid" title="Copy UUID"></i>
      </div>
    </header>

    <div class="dashboard-layout">
      <div class="info-card">
        <h3>Test Details</h3>
        <div class="info-row row-start">
          <span class="info-label">Start</span>
          <div class="info-dates">
            <span class="date-scheduled">Scheduled: {{ testData.startTime ? formatDateTime(testData.startTime) : 'Not set' }}</span>
            <span class="date-actual">Actual: {{ testData.startedAt ? formatDateTime(testData.startedAt) : '—' }}</span>
          </div>
        </div>
        <div class="info-row row-end">
          <span class="info-label">End</span>
          <div class="info-dates">
            <span class="date-scheduled">Scheduled: {{ testData.endTime ? formatDateTime(testData.endTime) : 'Not set' }}</span>
            <span class="date-actual">Actual: {{ testData.endedAt ? formatDateTime(testData.endedAt) : '—' }}</span>
          </div>
        </div>
        <div class="info-row">
          <span class="info-label">Status</span>
          <span class="info-value status-badge" :class="testStatus">{{ testStatus }}</span>
        </div>
      </div>
    </div>

    <div class="actions-footer">
      <button class="btn-danger" @click="deleteTest">Delete</button>
      <button class="btn-secondary" @click="openEditModal">Edit</button>
      <button class="btn-secondary" @click="router.push(`/proctoring/${testId}`)">Proctoring</button>
      <button v-if="testStatus === 'scheduled'" class="btn-primary" @click="startTest">Start</button>
      <button v-if="testStatus === 'live'" class="btn-primary" @click="endTest">End</button>
    </div>

    <!-- Edit Modal -->
    <div class="modal-overlay" v-if="showEditModal" @click.self="showEditModal = false">
      <div class="modal">
        <h2>Edit Test</h2>
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
        <h2>Delete Test</h2>
        <p class="delete-message">Are you sure you want to delete this test? This action cannot be undone.</p>
        <div class="modal-actions">
          <button class="btn-secondary" @click="showDeleteModal = false">Cancel</button>
          <button class="btn-danger" @click="confirmDelete">Delete</button>
        </div>
      </div>
    </div>

  </div>
  <div v-else class="view-management loading-state">
    <p>Loading test details...</p>
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
  0% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7); }
  70% { box-shadow: 0 0 0 6px rgba(255, 255, 255, 0); }
  100% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0); }
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
  border: 1px solid #ef4444;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  color: #ef4444;
  transition: background 0.15s;
}
.btn-danger:hover {
  background: rgba(239, 68, 68, 0.1);
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
