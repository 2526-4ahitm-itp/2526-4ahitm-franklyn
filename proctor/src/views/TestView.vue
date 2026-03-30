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
  startTime: string | null
  endTime: string | null
}

const testsList = ref<Test[]>([])
const showWizard = ref(false)
const newTestTitle = ref('')

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
          }
        }
      `,
      fetchPolicy: 'network-only'
    })
    .then((res) => {
      if (res.data?.tests !== undefined) {
        testsList.value = res.data.tests
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

  client.mutate<{ createTest: Test }>({
    mutation: gql`
      mutation CreateTest($test: TestInput!) {
        createTest(test: $test) {
          id
        }
      }
    `,
    variables: {
      test: { title }
    }
  }).then(async (res) => {
    if (res.data?.createTest?.id) {
      await router.push('/tests/' + res.data.createTest.id)
    }
  }).catch(e => {
    console.error("Failed to create test", e)
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
  return 'Not started'
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

    <!-- Wizard Modal -->
    <div v-if="showWizard" class="wizard-overlay" @click.self="showWizard = false">
      <div class="wizard-modal">
        <div class="wizard-header">
          <h3>Create a New Test</h3>
          <button class="close-btn" @click="showWizard = false">&times;</button>
        </div>
        <div class="wizard-body">
          <p class="wizard-description">Set up a new test session. You will be able to manage students and start the exam on the next screen.</p>
          <div class="form-group">
            <label for="testTitle">Exam Title</label>
            <input
              id="testTitle"
              type="text"
              v-model="newTestTitle"
              placeholder="e.g., Mathematics Midterm"
              class="wizard-input"
              @keyup.enter="createTest"
              autofocus
            />
          </div>
        </div>
        <div class="wizard-footer">
          <button class="btn-secondary" @click="showWizard = false">Cancel</button>
          <button class="btn-primary" @click="createTest" :disabled="!newTestTitle.trim()">Create Test</button>
        </div>
      </div>
    </div>

    <div class="test-list">
      <div
        v-for="test in testsList"
        :key="test.id"
        class="test-row"
        @click="goToTest(test.id)"
      >
        <div class="test-row-content">
          <div class="test-details">
            <div class="test-title-row">
              <h3 class="test-name">{{ test.title || 'Untitled Test' }}</h3>
              <span class="class-badge">CLASS</span>
            </div>
            <div class="test-meta-row">
              <span class="test-meta">PIN {{ test.pin || 'N/A' }}</span>
              <span class="test-meta-separator">·</span>
              <span class="test-meta">{{ getTestTime(test) }}</span>
            </div>
          </div>
          <div class="test-status-badge">
            <span class="badge" :class="test.endTime ? 'status-completed' : (test.startTime ? 'status-live' : 'status-prep')">
              {{ test.endTime ? 'Done' : (test.startTime ? 'Live' : 'Preparation') }}
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

/* Wizard Modal Styles */
.wizard-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.wizard-modal {
  background: var(--bg-modal);
  border-radius: 16px;
  width: 90%;
  max-width: 500px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: modal-fade-in 0.3s ease-out;
}

@keyframes modal-fade-in {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.wizard-header {
  padding: 20px 24px;
  border-bottom: 1px solid var(--border-default);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--bg-card);
}

.wizard-header h3 {
  margin: 0;
  color: var(--text-primary);
  font-size: 1.25rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: var(--text-secondary);
  cursor: pointer;
  line-height: 1;
  padding: 0;
}
.close-btn:hover {
  color: var(--text-primary);
}

.wizard-body {
  padding: 24px;
}

.wizard-description {
  color: var(--text-secondary);
  margin-top: 0;
  margin-bottom: 20px;
  font-size: 0.95rem;
  line-height: 1.5;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-weight: 600;
  color: var(--text-primary);
  font-size: 0.9rem;
}

.wizard-input {
  padding: 12px 16px;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--bg-input);
  color: var(--text-primary);
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;
}

.wizard-input:focus {
  border-color: var(--primary);
}

.wizard-footer {
  padding: 16px 24px;
  background: var(--bg-card);
  border-top: 1px solid var(--border-default);
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.btn-secondary {
  background: transparent;
  color: var(--text-primary);
  border: 1px solid var(--border-strong);
  padding: 10px 20px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: 0.2s;
}

.btn-secondary:hover {
  background: var(--border-default);
}

.btn-primary {
  background: var(--primary);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
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

.badge {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: capitalize;
}
.status-completed {
  background: hsla(265, 55%, 55%, 0.15);
  color: hsl(265, 55%, 55%);
}
.status-live {
  background: hsla(145, 55%, 45%, 0.15);
  color: hsl(145, 55%, 45%);
}
.status-prep {
  background: hsla(210, 85%, 55%, 0.15);
  color: hsl(210, 85%, 55%);
}

</style>
