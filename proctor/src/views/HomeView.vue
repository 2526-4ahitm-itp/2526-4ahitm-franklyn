<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const { client } = useApolloClientStore()
const router = useRouter()

interface Exam {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: Date | null
  endTime: Date | null
  startedAt: Date | null
  endedAt: Date | null
}

const examsList = ref<Exam[]>([])
const showWizard = ref(false)
const newExamTitle = ref('')
const newExamDate = ref('')
const newExamStartTime = ref('')
const newExamEndTime = ref('')
const activeFilter = ref<'all' | 'live' | 'scheduled' | 'completed'>('all')

function setFilter(filter: 'all' | 'live' | 'scheduled' | 'completed') {
  activeFilter.value = filter
}

function getExamStatus(exam: Exam): 'live' | 'completed' | 'scheduled' {
  if (!exam.startedAt) return 'scheduled'
  if (!exam.endedAt) return 'live'
  return 'completed'
}

function isState(exam: Exam, filter: 'all' | 'live' | 'scheduled' | 'completed'): boolean {
  if (filter === 'all') return true;
  const status = getExamStatus(exam)
  return status === filter;
}

function fetchExams() {
  client
    .query<{ exams: Exam[] }>({
      query: gql`
        query GetExams {
          exams {
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
      fetchPolicy: 'network-only',
    })
    .then((res) => {
      if (res.data?.exams !== undefined) {
        examsList.value = res.data.exams
        console.log(examsList.value);
      }
    })
    .catch(() => {
      console.error('Failed to fetch exams!')
    })
}

fetchExams()

function createExam() {
  const title = newExamTitle.value
  if (!title) return

  let startTime: string | null = null
  let endTime: string | null = null

  if (newExamDate.value && newExamStartTime.value) {
    const [startHours = 0, startMinutes = 0] = newExamStartTime.value.split(':').map(Number)
    const dateParts = newExamDate.value.split('-').map(Number)
    const year = dateParts[0] ?? 0
    const month = (dateParts[1] ?? 1) - 1
    const day = dateParts[2] ?? 1
    const startDate = new Date(year, month, day, startHours, startMinutes, 0, 0)
    startTime = startDate.toISOString()

    if (newExamEndTime.value) {
      const [endHours = 0, endMinutes = 0] = newExamEndTime.value.split(':').map(Number)
      const endDate = new Date(year, month, day, endHours, endMinutes, 0, 0)
      endTime = endDate.toISOString()
    }
  }

  client
    .mutate<{ createExam: Exam }>({
      mutation: gql`
        mutation CreateExam($exam: InsertExamInput!) {
          createExam(examInput: $exam) {
            id
          }
        }
      `,
      variables: {
        exam: { title, startTime, endTime },
      },
    })
    .then(async (res) => {
      if (res.data?.createExam?.id) {
        showWizard.value = false
        newExamTitle.value = ''
        newExamDate.value = ''
        newExamStartTime.value = ''
        newExamEndTime.value = ''
        await router.push('/exams/' + res.data.createExam.id)
      }
    })
    .catch((e) => {
      console.error('Failed to create exam', e)
    })
}

function formatTime(date: Date) {
  return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}

function getExamTime(exam: Exam): string {
  if (exam.endTime && exam.startTime) {
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

async function goToExam(id: string) {
  await router.push('/exams/' + id)
}
</script>

<template>
  <div class="view-management">
    <div class="section-header">
      <h2>Your Exams</h2>
      <button class="btn-primary" @click="showWizard = true">Create New Exam</button>
    </div>

    <!-- Create Exam Modal -->
    <div v-if="showWizard" class="modal-overlay" @click.self="showWizard = false">
      <div class="modal">
        <h2>Create Exam</h2>
        <div class="form-group">
          <label for="examTitle">Title</label>
          <input id="examTitle" type="text" v-model="newExamTitle" />
        </div>
        <div class="form-group">
          <label for="examDate">Date</label>
          <input id="examDate" type="date" v-model="newExamDate" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label for="examStartTime">Start Time</label>
            <input id="examStartTime" type="time" v-model="newExamStartTime" />
          </div>
          <div class="form-group">
            <label for="examEndTime">End Time</label>
            <input id="examEndTime" type="time" v-model="newExamEndTime" />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn-secondary" @click="showWizard = false">Cancel</button>
          <button class="btn-primary" @click="createExam" :disabled="!newExamTitle.trim()">Create</button>
        </div>
      </div>
    </div>

    <div class="filter-pills">
      <button
        class="filter-pill"
        :class="{ active: activeFilter === 'all' }"
        @click="setFilter('all')"
        @keydown.enter="setFilter('all')"
        @keydown.space.prevent="setFilter('all')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'all'"
      >
        All
      </button>
      <button
        class="filter-pill status-live"
        :class="{ active: activeFilter === 'live' }"
        @click="setFilter('live')"
        @keydown.enter="setFilter('live')"
        @keydown.space.prevent="setFilter('live')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'live'"
      >
        Live
      </button>
      <button
        class="filter-pill status-scheduled"
        :class="{ active: activeFilter === 'scheduled' }"
        @click="setFilter('scheduled')"
        @keydown.enter="setFilter('scheduled')"
        @keydown.space.prevent="setFilter('scheduled')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'scheduled'"
      >
        Scheduled
      </button>
      <button
        class="filter-pill status-completed"
        :class="{ active: activeFilter === 'completed' }"
        @click="setFilter('completed')"
        @keydown.enter="setFilter('completed')"
        @keydown.space.prevent="setFilter('completed')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'completed'"
      >
        Completed
      </button>
    </div>

    <div class="exam-list">
      <div v-for="exam in examsList.filter(e => isState(e, activeFilter))" :key="exam.id" class="exam-row" @click="goToExam(exam.id)">
        <div class="exam-row-content">
          <div class="exam-details">
            <div class="exam-title-row">
              <h3 class="exam-name">{{ exam.title || 'Untitled Exam' }}</h3>
            </div>
            <div class="exam-meta-row">
              <span class="exam-meta exam-meta-pin">PIN {{ exam.pin || 'N/A' }}</span>
              <span class="exam-meta-separator">·</span>
              <span class="exam-meta">{{ getExamTime(exam) }}</span>
            </div>
          </div>
          <div class="exam-status-badge">
            <span class="badge" :class="'status-' + getExamStatus(exam)">
              {{ getExamStatus(exam) === 'completed' ? 'Completed' : getExamStatus(exam) === 'live' ? 'Live' : 'Scheduled' }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.view-management {
  padding: 40px;
  max-width: 1200px;
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
}
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.section-header h2 {
  color: var(--text-primary);
  margin: 0;
  font-size: 1.5rem;
}

.filter-pills {
  display: flex;
  gap: 10px;
  margin-bottom: 24px;
}

.filter-pill {
  padding: 8px 18px;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
  border: none;
  background: var(--bg-card);
  color: var(--text-secondary);
  cursor: pointer;
  box-shadow: inset 0 0 0 2px transparent;
  transition: color 0.2s ease, background-color 0.2s ease, box-shadow 0.2s ease;
}

.filter-pill:hover {
  background: var(--border-default);
  color: var(--text-primary);
}

.filter-pill:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.filter-pill.active {
  box-shadow: inset 0 0 0 2px var(--primary);
  color: var(--primary);
  background: transparent;
}

.filter-pill.active.status-live {
  box-shadow: inset 0 0 0 2px var(--status-live);
  color: var(--status-live);
}

.filter-pill.active.status-scheduled {
  box-shadow: inset 0 0 0 2px var(--status-scheduled);
  color: var(--status-scheduled);
}

.filter-pill.active.status-completed {
  box-shadow: inset 0 0 0 2px var(--status-completed);
  color: var(--status-completed);
}

/* Modal Styles */
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
  display: flex;
  flex-direction: column;
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
  outline: none;
  transition: border-color 0.2s;
}

.form-group input:focus {
  border-color: var(--primary);
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

.exam-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.exam-row {
  background: var(--bg-card);
  padding: 20px 24px;
  border-radius: 12px;
  border: 1px solid var(--border-default);
  cursor: pointer;
  transition: all 0.2s ease;
}
.exam-row:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}
.exam-row-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
.exam-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.exam-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}
.exam-name {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-primary);
}
.class-badge {
  background-color: var(--bg-input);
  color: var(--text-secondary);
  font-size: 0.75rem;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 6px;
  text-transform: uppercase;
}
.exam-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  color: var(--text-secondary);
}
.exam-meta-separator {
  color: var(--text-tertiary);
}

.exam-meta-pin {
  font-family: 'JetBrains Mono';
}

.badge {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: capitalize;
}
.status-completed {
  background: var(--status-completed);
  color: white;
}
.status-live {
  background: var(--status-live);
  color: white;
}
.status-scheduled {
  background: var(--status-scheduled);
  color: white;
}
</style>
