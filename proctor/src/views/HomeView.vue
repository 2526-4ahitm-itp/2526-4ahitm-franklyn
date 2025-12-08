<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import type { Test, CreateTestPayload } from '@/services/testService'
import { listTests, createTest, deleteTest } from '@/services/testService'

const router = useRouter()
const tests = ref<Test[]>([])
const isLoading = ref(false)
const isCreating = ref(false)
const errorMessage = ref<string | null>(null)
const showCreateForm = ref(false)

const newTest = ref<CreateTestPayload>({
  title: '',
  testAccountPrefix: '',
})

async function fetchTests(): Promise<void> {
  isLoading.value = true
  errorMessage.value = null
  try {
    tests.value = await listTests()
  } catch {
    errorMessage.value = 'Failed to load tests.'
  } finally {
    isLoading.value = false
  }
}

async function handleCreateTest(): Promise<void> {
  if (!newTest.value.title.trim()) {
    errorMessage.value = 'Title is required.'
    return
  }

  if (!newTest.value.testAccountPrefix?.trim()) {
    errorMessage.value = 'Account prefix is required.'
    return
  }

  isCreating.value = true
  errorMessage.value = null

  try {
    const payload: CreateTestPayload = {
      title: newTest.value.title.trim(),
      testAccountPrefix: newTest.value.testAccountPrefix.trim(),
    }

    const createdTest = await createTest(payload)
    tests.value.unshift(createdTest)
    newTest.value = { title: '', testAccountPrefix: '' }
    showCreateForm.value = false
  } catch {
    errorMessage.value = 'Failed to create test.'
  } finally {
    isCreating.value = false
  }
}

async function handleDeleteTest(id: number): Promise<void> {
  try {
    await deleteTest(id)
    tests.value = tests.value.filter((t) => t.id !== id)
  } catch {
    errorMessage.value = 'Failed to delete test.'
  }
}

function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return ''
  // Backend sends UTC, convert to local for display
  const date = new Date(dateString.endsWith('Z') ? dateString : dateString + 'Z')
  return date.toLocaleString()
}

function getTestStatus(test: Test): { label: string; class: string } {
  const start = test.start ?? test.startTime
  const end = test.end ?? test.endTime
  if (end) {
    return { label: 'Ended', class: 'ended' }
  }
  if (start) {
    return { label: 'Live', class: 'running' }
  }
  return { label: 'Pending', class: 'pending' }
}

function openTest(id: number): void {
  void router.push({ name: 'test', params: { id } })
}

onMounted(() => {
  void fetchTests()
})
</script>

<template>
  <div class="container">
    <div v-if="errorMessage" class="error">
      {{ errorMessage }}
      <button @click="errorMessage = null"><i class="bi bi-x" /></button>
    </div>

    <div class="toolbar">
      <button class="btn-create" @click="showCreateForm = !showCreateForm">
        <i :class="showCreateForm ? 'bi bi-x' : 'bi bi-plus'" />
        {{ showCreateForm ? 'Cancel' : 'New Test' }}
      </button>
    </div>

    <div v-if="showCreateForm" class="create-form">
      <form @submit.prevent="handleCreateTest">
        <input
          v-model="newTest.title"
          type="text"
          placeholder="Test title"
          :disabled="isCreating"
          required
        />
        <input
          v-model="newTest.testAccountPrefix"
          type="text"
          placeholder="Account prefix"
          :disabled="isCreating"
          required
        />
        <button type="submit" :disabled="isCreating">
          {{ isCreating ? 'Creating...' : 'Create' }}
        </button>
      </form>
    </div>

    <div v-if="isLoading" class="loading">Loading...</div>

    <div v-else-if="tests.length === 0" class="empty">No tests yet.</div>

    <div v-else class="tests-grid">
      <div v-for="test in tests" :key="test.id" class="test-card" @click="openTest(test.id)">
        <div class="test-card-header">
          <h3 class="test-title">{{ test.title }}</h3>
          <div class="test-card-actions">
            <span :class="['status-badge', getTestStatus(test).class]">
              {{ getTestStatus(test).label }}
            </span>
            <button class="btn-delete" @click.stop="handleDeleteTest(test.id)">
              <i class="bi bi-trash" />
            </button>
          </div>
        </div>
        <div class="test-meta">
          <span v-if="test.testAccountPrefix">{{ test.testAccountPrefix }}</span>
          <span>{{ formatDate(test.start ?? test.startTime) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.container {
  max-width: 960px;
  margin: 0 auto;
  padding: 2rem;
  font-family: system-ui, -apple-system, sans-serif;
  background: hsl(210, 20%, 98%);
  min-height: 100vh;
}

.error {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  margin-bottom: 1rem;
  background: hsla(0, 78%, 55%, 0.2);
  color: hsl(0, 78%, 35%);
  border-radius: 6px;
  border: 1px solid hsl(0, 78%, 55%);
}

.error button {
  background: none;
  border: none;
  cursor: pointer;
  color: inherit;
  font-size: 1.25rem;
  line-height: 1;
}

.toolbar {
  margin-bottom: 1.5rem;
}

.btn-create {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 1.2rem;
  background: hsl(185, 72%, 45%);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-create:hover {
  background: hsl(185, 72%, 35%);
}

.btn-create:active {
  background: hsl(185, 72%, 30%);
}

.create-form {
  margin-bottom: 1.5rem;
  padding: 1.25rem;
  background: hsl(210, 15%, 94%);
  border: 1px solid hsl(210, 10%, 88%);
  border-radius: 8px;
}

.create-form form {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.create-form input {
  flex: 1;
  min-width: 180px;
  padding: 0.6rem 0.75rem;
  font-size: 0.95rem;
  border: 1px solid hsl(210, 10%, 88%);
  border-radius: 6px;
  background: hsl(210, 15%, 94%);
  color: hsl(225, 15%, 15%);
}

.create-form input:focus {
  outline: none;
  border-color: hsl(210, 85%, 55%);
  box-shadow: 0 0 0 2px hsla(210, 85%, 55%, 0.2);
}

.create-form input::placeholder {
  color: hsl(210, 10%, 60%);
}

.create-form button {
  padding: 0.6rem 1.2rem;
  background: hsl(145, 55%, 45%);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s;
}

.create-form button:hover:not(:disabled) {
  background: hsl(145, 55%, 38%);
}

.create-form button:disabled {
  background: hsl(185, 15%, 45%);
  cursor: not-allowed;
}

.loading,
.empty {
  text-align: center;
  padding: 3rem 1rem;
  color: hsl(210, 10%, 60%);
}

.tests-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
}

.test-card {
  background: hsl(210, 15%, 94%);
  border: 1px solid hsl(210, 10%, 88%);
  border-radius: 8px;
  padding: 1rem;
  transition: border-color 0.15s;
  cursor: pointer;
}

.test-card:hover {
  border-color: hsl(185, 72%, 45%);
}

.test-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.test-card-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.2rem 0.5rem;
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.status-badge.pending {
  background: hsla(210, 10%, 50%, 0.2);
  color: hsl(210, 10%, 40%);
}

.status-badge.running {
  background: hsla(145, 55%, 45%, 0.2);
  color: hsl(145, 55%, 30%);
}

.status-badge.ended {
  background: hsla(35, 90%, 50%, 0.2);
  color: hsl(35, 90%, 35%);
}

.btn-delete {
  background: none;
  border: none;
  color: hsl(210, 10%, 60%);
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  transition: color 0.15s, background 0.15s;
}

.btn-delete:hover {
  color: hsl(0, 78%, 55%);
  background: hsla(0, 78%, 55%, 0.1);
}

.test-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: hsl(225, 15%, 15%);
}

.test-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  font-size: 0.85rem;
  color: hsl(210, 10%, 40%);
}
</style>

