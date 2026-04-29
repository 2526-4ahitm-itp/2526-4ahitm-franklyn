<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useNoticeStore } from '@/stores/NoticeStore'
import UiButton from '@/components/ui/Button.vue'
import type { NoticeType } from '@/types/Notice'

const noticeStore = useNoticeStore()
const { notices, loading, error } = storeToRefs(noticeStore)
const { fetchNotices, createNotice } = noticeStore

const showCreateModal = ref(false)
const noticeType = ref<NoticeType>('ALERT')
const noticeContent = ref('')
const noticeStart = ref('')
const noticeEnd = ref('')
const createError = ref('')

const hasNotices = computed(() => notices.value.length > 0)
const sortedNotices = computed(() => {
  return [...notices.value].sort((a, b) => {
    const aStart = a.startTime ? new Date(a.startTime).getTime() : 0
    const bStart = b.startTime ? new Date(b.startTime).getTime() : 0
    return bStart - aStart
  })
})

const canSubmit = computed(() => {
  if (!noticeContent.value.trim()) return false
  if (noticeType.value === 'TIMED') return Boolean(noticeStart.value && noticeEnd.value)
  return true
})

function formatDate(value: Date | null) {
  if (!value) return 'N/A'
  return value.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function formatTypeLabel(type: NoticeType) {
  if (type === 'SINGLE') return 'One Time'
  if (type === 'TIMED') return 'Timed'
  return 'Alert'
}

function resetForm() {
  noticeType.value = 'ALERT'
  noticeContent.value = ''
  noticeStart.value = ''
  noticeEnd.value = ''
  createError.value = ''
}

function closeModal() {
  showCreateModal.value = false
  resetForm()
}

function parseDateTime(value: string): Date | null {
  if (!value) return null
  const date = new Date(value)
  return isNaN(date.getTime()) ? null : date
}

async function submitNotice() {
  createError.value = ''
  if (!noticeContent.value.trim()) {
    createError.value = 'Content is required.'
    return
  }

  const startTime = noticeType.value === 'TIMED' ? parseDateTime(noticeStart.value) : null
  const endTime = noticeType.value === 'TIMED' ? parseDateTime(noticeEnd.value) : null

  if (noticeType.value === 'TIMED') {
    if (!startTime || !endTime) {
      createError.value = 'Start and end time are required.'
      return
    }
    if (endTime <= startTime) {
      createError.value = 'End time must be after start time.'
      return
    }
  }

  try {
    await createNotice({
      type: noticeType.value,
      content: noticeContent.value.trim(),
      startTime,
      endTime,
    })
    closeModal()
  } catch (err) {
    console.error(err)
    createError.value = 'Failed to create notice.'
  }
}

onMounted(() => {
  void fetchNotices()
})
</script>

<template>
  <main class="view-management">
    <div class="section-header">
      <h2>Notice Banners</h2>
      <UiButton variant="primary" @click="showCreateModal = true">Create notice</UiButton>
    </div>

    <section class="notice-section">
      <p v-if="loading" class="status-message">Loading notices...</p>
      <p v-else-if="error" class="status-message status-error">{{ error }}</p>
      <p v-else-if="!hasNotices" class="status-message">No notices yet.</p>

      <div v-else class="notice-list">
        <div v-for="notice in sortedNotices" :key="notice.id" class="notice-row">
          <div class="notice-row-content">
            <div class="notice-details">
              <div class="notice-title-row">
                <h3 class="notice-title">{{ notice.content }}</h3>
              </div>
              <div v-if="notice.type === 'TIMED'" class="notice-meta-row">
                <span class="notice-meta">{{ formatDate(notice.startTime) }}</span>
                <span class="notice-meta-separator">·</span>
                <span class="notice-meta">{{ formatDate(notice.endTime) }}</span>
              </div>
            </div>
            <div class="notice-status-badge">
              <span class="badge" :class="`status-${notice.type.toLowerCase()}`">
                {{ formatTypeLabel(notice.type) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <div v-if="showCreateModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <header class="modal-header">
          <h2>Create notice</h2>
          <button class="icon-button" type="button" @click="closeModal" aria-label="Close">
            <i class="bi bi-x-lg"></i>
          </button>
        </header>
        <form class="modal-body" @submit.prevent="submitNotice">
          <div class="form-group">
            <label for="noticeType">Type</label>
            <select id="noticeType" v-model="noticeType" class="form-control" required>
              <option value="ALERT">Alert</option>
              <option value="TIMED">Timed</option>
              <option value="SINGLE">One Time</option>
            </select>
          </div>
          <div class="form-group">
            <label for="noticeContent">Content</label>
            <textarea
              id="noticeContent"
              v-model="noticeContent"
              class="form-control"
              rows="4"
              minlength="3"
              maxlength="4096"
              required
            ></textarea>
          </div>
          <div v-if="noticeType === 'TIMED'" class="form-row">
            <div class="form-group">
              <label for="noticeStart">Start time</label>
              <input id="noticeStart" v-model="noticeStart" type="datetime-local" class="form-control" required />
            </div>
            <div class="form-group">
              <label for="noticeEnd">End time</label>
              <input id="noticeEnd" v-model="noticeEnd" type="datetime-local" class="form-control" required />
            </div>
          </div>
          <p v-if="createError" class="form-error">{{ createError }}</p>
          <div class="modal-actions">
            <UiButton variant="secondary" type="button" @click="closeModal">Cancel</UiButton>
            <UiButton variant="primary" type="submit" :disabled="!canSubmit">Create</UiButton>
          </div>
        </form>
      </div>
    </div>
  </main>
</template>

<style scoped>
.view-management {
  padding: 40px;
  max-width: 1200px;
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
  color: var(--text-primary);
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

.notice-section {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 1rem;
}

.status-message {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.status-error {
  color: var(--error);
}

.notice-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 1rem;
}

.notice-row {
  background: var(--bg-card);
  padding: 20px 24px;
  border-radius: 12px;
  border: 1px solid var(--border-default);
  transition: all 0.2s ease;
}

.notice-row:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.notice-row-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  gap: 1rem;
}

.notice-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.notice-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.notice-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-primary);
}

.notice-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.notice-meta-separator {
  color: var(--text-tertiary);
}

.notice-status-badge {
  flex-shrink: 0;
}

.badge {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: capitalize;
  color: white;
}

.status-alert {
  background: var(--status-live);
}

.status-timed {
  background: var(--status-scheduled);
}

.status-single {
  background: var(--status-completed);
}

@media (max-width: 720px) {
  .view-management {
    padding: 20px;
  }

  .notice-row-content {
    flex-direction: column;
    align-items: flex-start;
  }
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
  padding: 1.25rem;
  width: 420px;
  max-width: 92vw;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.modal-header h2 {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
}

.icon-button {
  border: 1px solid var(--border-default);
  background: transparent;
  color: var(--text-secondary);
  width: 2rem;
  height: 2rem;
  border-radius: 8px;
  cursor: pointer;
}

.icon-button:hover {
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.form-group label {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-secondary);
}

.form-control {
  padding: 0.55rem 0.75rem;
  border: 1px solid var(--border-default);
  border-radius: 8px;
  background: var(--bg-subtle);
  color: var(--text-primary);
  font-size: 0.9rem;
}

.form-control:focus {
  outline: 2px solid var(--primary);
  outline-offset: 1px;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.8rem;
}

.form-error {
  margin: 0;
  font-size: 0.85rem;
  color: var(--error);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.6rem;
}
</style>
