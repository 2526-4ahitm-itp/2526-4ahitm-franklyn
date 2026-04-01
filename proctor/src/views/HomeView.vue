<script setup lang="ts">
import { useApolloClientStore } from '@/stores/ApolloClientStore'
import { gql } from '@apollo/client'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const { client } = useApolloClientStore()
const router = useRouter()

interface Test {
  id: string
  title: string
  pin: number
  teacherId: string
  startTime: Date | null
  endTime: Date | null
  startedAt: Date | null
  endedAt: Date | null
}

const testsList = ref<Test[]>([])
const showWizard = ref(false)
const newTestTitle = ref('')
const newTestDate = ref('')
const newTestStartTime = ref('')
const newTestEndTime = ref('')
const activeFilter = ref<'all' | 'live' | 'scheduled' | 'completed'>('all')

function setFilter(filter: 'all' | 'live' | 'scheduled' | 'completed') {
  activeFilter.value = filter
}

function getTestStatus(test: Test): 'live' | 'completed' | 'scheduled' {
  if (!test.startedAt) return 'scheduled'
  if (!test.endedAt) return 'live'
  return 'completed'
}

function isState(test: Test, filter: 'all' | 'live' | 'scheduled' | 'completed'): boolean {
  if (filter === 'all') return true;
  const status = getTestStatus(test)
  return status === filter;
}

function fetchTests() {
  client
    .query<{ tests: Test[] }>({
      query: gql`
        query GetTests {
          tests {
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
      if (res.data?.tests !== undefined) {
        testsList.value = res.data.tests
        console.log(testsList.value);
      }
    })
    .catch(() => {
      console.error('Failed to fetch tests!')
    })
}

fetchTests()

function createTest() {
  const title = newTestTitle.value
  if (!title) return

  let startTime: string | null = null
  let endTime: string | null = null

  if (newTestDate.value && newTestStartTime.value) {
    const startDate = new Date(newTestDate.value)
    const [startHours = 0, startMinutes = 0] = newTestStartTime.value.split(':').map(Number)
    startDate.setHours(startHours, startMinutes, 0, 0)
    startTime = startDate.toISOString()

    if (newTestEndTime.value) {
      const endDate = new Date(newTestDate.value)
      const [endHours = 0, endMinutes = 0] = newTestEndTime.value.split(':').map(Number)
      endDate.setHours(endHours, endMinutes, 0, 0)
      endTime = endDate.toISOString()
    }
  }

  client
    .mutate<{ createTest: Test }>({
      mutation: gql`
        mutation CreateTest($test: InsertTestInput!) {
          createTest(testInput: $test) {
            id
          }
        }
      `,
      variables: {
        test: { title, startTime, endTime },
      },
    })
    .then(async (res) => {
      if (res.data?.createTest?.id) {
        showWizard.value = false
        newTestTitle.value = ''
        newTestDate.value = ''
        newTestStartTime.value = ''
        newTestEndTime.value = ''
        await router.push('/tests/' + res.data.createTest.id)
      }
    })
    .catch((e) => {
      console.error('Failed to create test', e)
    })
}

function formatTime(date: Date) {
  return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}

function getTestTime(test: Test): string {
  if (test.endTime && test.startTime) {
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

async function goToTest(id: string) {
  await router.push('/tests/' + id)
}
</script>

<template>
  <div class="view-management">
    <div class="section-header">
      <h2>Your Tests</h2>
      <button class="btn-primary" @click="showWizard = true">Create New Test</button>
    </div>

    <!-- Create Test Modal -->
    <div v-if="showWizard" class="modal-overlay" @click.self="showWizard = false">
      <div class="modal">
        <h2>Create Test</h2>
        <div class="form-group">
          <label for="testTitle">Title</label>
          <input id="testTitle" type="text" v-model="newTestTitle" />
        </div>
        <div class="form-group">
          <label for="testDate">Date</label>
          <input id="testDate" type="date" v-model="newTestDate" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label for="testStartTime">Start Time</label>
            <input id="testStartTime" type="time" v-model="newTestStartTime" />
          </div>
          <div class="form-group">
            <label for="testEndTime">End Time</label>
            <input id="testEndTime" type="time" v-model="newTestEndTime" />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn-secondary" @click="showWizard = false">Cancel</button>
          <button class="btn-primary" @click="createTest" :disabled="!newTestTitle.trim()">Create</button>
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

    <div class="test-list">
      <div v-for="test in testsList.filter(e => isState(e, activeFilter))" :key="test.id" class="test-row" @click="goToTest(test.id)">
        <div class="test-row-content">
          <div class="test-details">
            <div class="test-title-row">
              <h3 class="test-name">{{ test.title || 'Untitled Test' }}</h3>
            </div>
            <div class="test-meta-row">
              <span class="test-meta test-meta-pin">PIN {{ test.pin || 'N/A' }}</span>
              <span class="test-meta-separator">·</span>
              <span class="test-meta">{{ getTestTime(test) }}</span>
            </div>
          </div>
          <div class="test-status-badge">
            <span class="badge" :class="'status-' + getTestStatus(test)">
              {{ getTestStatus(test) === 'completed' ? 'Completed' : getTestStatus(test) === 'live' ? 'Live' : 'Scheduled' }}
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
  border: 1px solid var(--border-default);
  background: var(--bg-card);
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.2s ease;
}

.filter-pill:hover {
  border-color: var(--primary);
  color: var(--text-primary);
}

.filter-pill:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.filter-pill.active {
  border-color: transparent;
  color: white;
}

.filter-pill.active.status-live {
  background: var(--status-live);
}

.filter-pill.active.status-scheduled {
  background: var(--status-scheduled);
}

.filter-pill.active.status-completed {
  background: var(--status-completed);
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

.test-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.test-row {
  background: var(--bg-card);
  padding: 20px 24px;
  border-radius: 12px;
  border: 1px solid var(--border-default);
  cursor: pointer;
  transition: all 0.2s ease;
}
.test-row:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}
.test-row-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
.test-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.test-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}
.test-name {
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
.test-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  color: var(--text-secondary);
}
.test-meta-separator {
  color: var(--text-tertiary);
}

.test-meta-pin {
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
