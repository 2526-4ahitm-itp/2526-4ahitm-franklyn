<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { Test } from '@/services/testService'
import { getTest, startTest, stopTest } from '@/services/testService'

const route = useRoute()
const router = useRouter()

const test = ref<Test | null>(null)
const isLoading = ref(false)
const isActioning = ref(false)
const errorMessage = ref<string | null>(null)

const testId = computed(() => Number(route.params.id))

const isRunning = computed(() => {
  const start = test.value?.start ?? test.value?.startTime
  const end = test.value?.end ?? test.value?.endTime
  return start !== null && start !== undefined && (end === null || end === undefined)
})

const hasEnded = computed(() => {
  const end = test.value?.end ?? test.value?.endTime
  return end !== null && end !== undefined
})

const testStatus = computed(() => {
  const start = test.value?.start ?? test.value?.startTime
  const end = test.value?.end ?? test.value?.endTime
  if (end) {
    return { label: 'Ended', class: 'ended' }
  }
  if (start) {
    return { label: 'Live', class: 'running' }
  }
  return { label: 'Pending', class: 'pending' }
})

async function fetchTest(): Promise<void> {
  isLoading.value = true
  errorMessage.value = null
  try {
    test.value = await getTest(testId.value)
  } catch {
    errorMessage.value = 'Failed to load test.'
  } finally {
    isLoading.value = false
  }
}

async function handleStart(): Promise<void> {
  isActioning.value = true
  errorMessage.value = null
  try {
    test.value = await startTest(testId.value)
  } catch {
    errorMessage.value = 'Failed to start test.'
  } finally {
    isActioning.value = false
  }
}

async function handleStop(): Promise<void> {
  isActioning.value = true
  errorMessage.value = null
  try {
    test.value = await stopTest(testId.value)
  } catch {
    errorMessage.value = 'Failed to stop test.'
  } finally {
    isActioning.value = false
  }
}

function goBack(): void {
  void router.push({ name: 'home' })
}

function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return ''
  // Backend sends UTC, convert to local for display
  const date = new Date(dateString.endsWith('Z') ? dateString : dateString + 'Z')
  return date.toLocaleString()
}

onMounted(() => {
  void fetchTest()
})
</script>

<template>
  <div class="container">
    <button class="btn-back" @click="goBack">
      <i class="bi bi-arrow-left" />
      Back to Tests
    </button>

    <div v-if="errorMessage" class="error">
      {{ errorMessage }}
      <button @click="errorMessage = null"><i class="bi bi-x" /></button>
    </div>

    <div v-if="isLoading" class="loading">Loading test...</div>

    <div v-else-if="!test" class="empty">Test not found.</div>

    <div v-else class="test-site">
      <div class="test-header">
        <h1 class="test-title">{{ test.title }}</h1>
        <span :class="['status-badge', testStatus.class]">
          {{ testStatus.label }}
        </span>
      </div>

      <div class="test-info">
        <div class="info-row">
          <span class="info-label">Account Prefix:</span>
          <span class="info-value">{{ test.testAccountPrefix || '—' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Start Time:</span>
          <span class="info-value">{{ formatDate(test.start ?? test.startTime) || '—' }}</span>
        </div>
        <div class="info-row">
          <span class="info-label">End Time:</span>
          <span class="info-value">{{ formatDate(test.end ?? test.endTime) || '—' }}</span>
        </div>
      </div>

      <div class="test-controls">
        <button
          v-if="!isRunning && !hasEnded"
          class="btn-start"
          :disabled="isActioning"
          @click="handleStart"
        >
          <i class="bi bi-play-fill" />
          {{ isActioning ? 'Starting...' : 'Start Test' }}
        </button>
        <button
          v-else-if="isRunning"
          class="btn-stop"
          :disabled="isActioning"
          @click="handleStop"
        >
          <i class="bi bi-stop-fill" />
          {{ isActioning ? 'Stopping...' : 'Stop Test' }}
        </button>
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

.btn-back {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  margin-bottom: 1.5rem;
  background: none;
  border: 1px solid hsl(210, 10%, 88%);
  border-radius: 6px;
  color: hsl(210, 10%, 40%);
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-back:hover {
  background: hsl(210, 15%, 94%);
  border-color: hsl(185, 72%, 45%);
  color: hsl(185, 72%, 35%);
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

.loading,
.empty {
  text-align: center;
  padding: 3rem 1rem;
  color: hsl(210, 10%, 60%);
}

.test-site {
  background: hsl(210, 15%, 94%);
  border: 1px solid hsl(210, 10%, 88%);
  border-radius: 12px;
  padding: 2rem;
}

.test-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}

.test-title {
  margin: 0;
  font-size: 1.75rem;
  font-weight: 700;
  color: hsl(225, 15%, 15%);
}

.status-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.35rem 0.75rem;
  border-radius: 999px;
  font-size: 0.8rem;
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

.status-badge.stopped {
  background: hsla(210, 10%, 50%, 0.2);
  color: hsl(210, 10%, 40%);
}

.status-badge.ended {
  background: hsla(35, 90%, 50%, 0.2);
  color: hsl(35, 90%, 35%);
}

.test-info {
  margin-bottom: 2rem;
}

.info-row {
  display: flex;
  gap: 0.75rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid hsl(210, 10%, 88%);
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  font-weight: 500;
  color: hsl(210, 10%, 40%);
  min-width: 120px;
}

.info-value {
  color: hsl(225, 15%, 15%);
}

.test-controls {
  display: flex;
  gap: 1rem;
}

.btn-start,
.btn-stop {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-start {
  background: hsl(145, 55%, 45%);
  color: white;
}

.btn-start:hover:not(:disabled) {
  background: hsl(145, 55%, 38%);
}

.btn-stop {
  background: hsl(0, 78%, 55%);
  color: white;
}

.btn-stop:hover:not(:disabled) {
  background: hsl(0, 78%, 45%);
}

.btn-start:disabled,
.btn-stop:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>

