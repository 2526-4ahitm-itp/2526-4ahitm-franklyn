<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { useNoticeStore } from '@/stores/NoticeStore'
import UiButton from '@/components/ui/Button.vue'
import NoticeBanner from '@/components/notice/NoticeBanner.vue'
import type { NoticeType } from '@/types/Notice'
import { renderNoticeMarkdown } from '@/utils/noticeMarkdown'

const noticeStore = useNoticeStore()
const { t, d } = useI18n()
const { notices, loading, error } = storeToRefs(noticeStore)
const { fetchNotices, createNotice, updateNotice, deleteNotice } = noticeStore

const showCreateModal = ref(false)
const noticeType = ref<NoticeType>('ALERT')
const noticeContent = ref('')
const noticeStart = ref('')
const noticeEnd = ref('')
const createError = ref('')

const showEditModal = ref(false)
const editNoticeId = ref<string | null>(null)
const editContent = ref('')
const editStart = ref('')
const editEnd = ref('')
const editError = ref('')

const showDeleteModal = ref(false)
const deleteNoticeId = ref<string | null>(null)
const deleteError = ref('')

const editNoticeType = computed(() => {
  if (!editNoticeId.value) return null
  return notices.value.find((notice) => notice.id === editNoticeId.value)?.type ?? null
})

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

function toDate(value: Date | string | null): Date | null {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return isNaN(date.getTime()) ? null : date
}

function formatDate(value: Date | string | null) {
  const date = toDate(value)
  if (!date) return t('notices.meta.na')
  return d(date, 'long')
}

function formatTypeLabel(type: NoticeType) {
  if (type === 'SINGLE') return t('notices.types.single')
  if (type === 'TIMED') return t('notices.types.timed')
  return t('notices.types.alert')
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

function resetEditForm() {
  editNoticeId.value = null
  editContent.value = ''
  editStart.value = ''
  editEnd.value = ''
  editError.value = ''
}

function closeEditModal() {
  showEditModal.value = false
  resetEditForm()
}

function openDeleteModal(noticeId: string) {
  deleteNoticeId.value = noticeId
  deleteError.value = ''
  showDeleteModal.value = true
}

function closeDeleteModal() {
  showDeleteModal.value = false
  deleteNoticeId.value = null
  deleteError.value = ''
}

function parseDateTime(value: string): Date | null {
  if (!value) return null
  const date = new Date(value)
  return isNaN(date.getTime()) ? null : date
}

function formatDateTimeInput(value: Date | string | null): string {
  const date = toDate(value)
  if (!date) return ''
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  const hours = `${date.getHours()}`.padStart(2, '0')
  const minutes = `${date.getMinutes()}`.padStart(2, '0')
  return `${year}-${month}-${day}T${hours}:${minutes}`
}

async function submitNotice() {
  createError.value = ''
  if (!noticeContent.value.trim()) {
    createError.value = t('notices.errors.content_required')
    return
  }

  const startTime = noticeType.value === 'TIMED' ? parseDateTime(noticeStart.value) : null
  const endTime = noticeType.value === 'TIMED' ? parseDateTime(noticeEnd.value) : null

  if (noticeType.value === 'TIMED') {
    if (!startTime || !endTime) {
      createError.value = t('notices.errors.start_end_required')
      return
    }
    if (endTime <= startTime) {
      createError.value = t('notices.errors.end_after_start')
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
    createError.value = t('notices.errors.create_failed')
  }
}

function openEditModal(notice: {
  id: string
  content: string
  startTime: Date | string | null
  endTime: Date | string | null
}) {
  editNoticeId.value = notice.id
  editContent.value = notice.content
  editStart.value = formatDateTimeInput(notice.startTime)
  editEnd.value = formatDateTimeInput(notice.endTime)
  editError.value = ''
  showEditModal.value = true
}

async function submitEdit() {
  editError.value = ''
  if (!editNoticeId.value) return
  if (!editContent.value.trim()) {
    editError.value = t('notices.errors.content_required')
    return
  }

  const startTime = editNoticeType.value === 'TIMED' ? parseDateTime(editStart.value) : null
  const endTime = editNoticeType.value === 'TIMED' ? parseDateTime(editEnd.value) : null

  if (editNoticeType.value === 'TIMED') {
    if (!startTime || !endTime) {
      editError.value = t('notices.errors.start_end_required')
      return
    }
    if (endTime <= startTime) {
      editError.value = t('notices.errors.end_after_start')
      return
    }
  }

  try {
    await updateNotice({
      id: editNoticeId.value,
      content: editContent.value.trim(),
      startTime,
      endTime,
    })
    closeEditModal()
  } catch (err) {
    console.error(err)
    editError.value = t('notices.errors.update_failed')
  }
}

async function confirmDelete() {
  deleteError.value = ''
  if (!deleteNoticeId.value) return
  try {
    await deleteNotice(deleteNoticeId.value)
    closeDeleteModal()
  } catch (err) {
    console.error(err)
    deleteError.value = t('notices.errors.delete_failed')
  }
}

onMounted(() => {
  void fetchNotices()
})
</script>

<template>
  <main class="view-management">
    <div class="section-header">
      <h2>{{ t('notices.title') }}</h2>
      <UiButton variant="primary" @click="showCreateModal = true">{{ t('notices.actions.create') }}</UiButton>
    </div>

    <section class="notice-section">
      <p v-if="loading && !hasNotices" class="status-message">{{ t('notices.status.loading') }}</p>
      <p v-else-if="!hasNotices" class="status-message">{{ t('notices.status.empty') }}</p>
      <p v-if="error" class="status-message status-error">{{ error }}</p>

      <div v-if="hasNotices" class="notice-list">
          <div v-for="notice in sortedNotices" :key="notice.id" class="notice-row">
            <div class="notice-row-content">
              <div class="notice-details">
                <div class="notice-title-row">
                  <h3 class="notice-title notice-markdown" v-safe-html="renderNoticeMarkdown(notice.content)"></h3>
                </div>
                <div v-if="notice.type === 'TIMED'" class="notice-meta-row">
                  <span class="notice-meta">{{ formatDate(notice.startTime) }}</span>
                  <span class="notice-meta-separator">·</span>
                  <span class="notice-meta">{{ formatDate(notice.endTime) }}</span>
                </div>
              </div>
              <div class="notice-actions">
                <span class="badge" :class="`status-${notice.type.toLowerCase()}`">
                  {{ formatTypeLabel(notice.type) }}
                </span>
                <UiButton variant="secondary" @click="openEditModal(notice)">{{ t('notices.actions.edit') }}</UiButton>
                <UiButton variant="danger" @click="openDeleteModal(notice.id)">{{ t('notices.actions.delete') }}</UiButton>
              </div>
            </div>
          </div>
        </div>
      </section>

    <div v-if="showCreateModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <header class="modal-header">
          <h2>{{ t('notices.create.title') }}</h2>
          <button class="icon-button" type="button" @click="closeModal" aria-label="Close">
            <i class="bi bi-x-lg"></i>
          </button>
        </header>
        <form class="modal-body" @submit.prevent="submitNotice">
          <div class="form-group">
            <label for="noticeType">{{ t('notices.fields.type') }}</label>
            <select id="noticeType" v-model="noticeType" class="form-control" required>
              <option value="ALERT">{{ t('notices.types.alert') }}</option>
              <option value="TIMED">{{ t('notices.types.timed') }}</option>
              <option value="SINGLE">{{ t('notices.types.single') }}</option>
            </select>
          </div>
          <div class="form-group">
            <label for="noticeContent">{{ t('notices.fields.content') }}</label>
            <textarea
              id="noticeContent"
              v-model="noticeContent"
              class="form-control"
              rows="4"
              minlength="3"
              maxlength="4096"
              required
            ></textarea>
            <details class="markdown-legend">
              <summary>{{ t('notices.markdown.title') }}</summary>
              <div class="markdown-legend-body">
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.bold') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.bold') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.italic') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.italic') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.strikethrough') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.strikethrough') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.inline_code') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.inline_code') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.link') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.link') }}</span>
                </div>
              </div>
            </details>
          </div>
          <div class="form-group">
            <label>{{ t('notices.fields.preview') }}</label>
            <NoticeBanner
              class="notice-preview-banner"
              :type="noticeType"
              :content-html="
                noticeContent.trim() ? renderNoticeMarkdown(noticeContent) : t('notices.preview.placeholder')
              "
              :dismissible="false"
            />
          </div>
          <div v-if="noticeType === 'TIMED'" class="form-row">
            <div class="form-group">
              <label for="noticeStart">{{ t('notices.fields.start_time') }}</label>
              <input id="noticeStart" v-model="noticeStart" type="datetime-local" class="form-control" required />
            </div>
            <div class="form-group">
              <label for="noticeEnd">{{ t('notices.fields.end_time') }}</label>
              <input id="noticeEnd" v-model="noticeEnd" type="datetime-local" class="form-control" required />
            </div>
          </div>
          <p v-if="createError" class="form-error">{{ createError }}</p>
          <div class="modal-actions">
            <UiButton variant="secondary" type="button" @click="closeModal">{{ t('notices.actions.cancel') }}</UiButton>
            <UiButton variant="primary" type="submit" :disabled="!canSubmit">{{ t('notices.actions.create') }}</UiButton>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showEditModal" class="modal-overlay" @click.self="closeEditModal">
      <div class="modal">
        <header class="modal-header">
          <h2>{{ t('notices.edit.title') }}</h2>
          <button class="icon-button" type="button" @click="closeEditModal" aria-label="Close">
            <i class="bi bi-x-lg"></i>
          </button>
        </header>
        <form class="modal-body" @submit.prevent="submitEdit">
          <div class="form-group">
            <label for="editNoticeType">{{ t('notices.fields.type') }}</label>
            <input
              id="editNoticeType"
              class="form-control"
              type="text"
              :value="editNoticeType ? formatTypeLabel(editNoticeType) : ''"
              disabled
            />
          </div>
          <div class="form-group">
            <label for="editNoticeContent">{{ t('notices.fields.content') }}</label>
            <textarea
              id="editNoticeContent"
              v-model="editContent"
              class="form-control"
              rows="4"
              minlength="3"
              maxlength="4096"
              required
            ></textarea>
            <details class="markdown-legend">
              <summary>{{ t('notices.markdown.title') }}</summary>
              <div class="markdown-legend-body">
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.bold') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.bold') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.italic') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.italic') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.strikethrough') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.strikethrough') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.inline_code') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.inline_code') }}</span>
                </div>
                <div class="markdown-legend-row">
                  <span class="markdown-legend-label">{{ t('notices.markdown.link') }}</span>
                  <span class="markdown-legend-example">{{ t('notices.markdown.examples.link') }}</span>
                </div>
              </div>
            </details>
          </div>
          <div class="form-group">
            <label>{{ t('notices.fields.preview') }}</label>
            <NoticeBanner
              class="notice-preview-banner"
              :type="editNoticeType ?? 'ALERT'"
              :content-html="editContent.trim() ? renderNoticeMarkdown(editContent) : t('notices.preview.placeholder')"
              :dismissible="false"
            />
          </div>
          <div v-if="editNoticeType === 'TIMED'" class="form-row">
            <div class="form-group">
              <label for="editNoticeStart">{{ t('notices.fields.start_time') }}</label>
              <input id="editNoticeStart" v-model="editStart" type="datetime-local" class="form-control" required />
            </div>
            <div class="form-group">
              <label for="editNoticeEnd">{{ t('notices.fields.end_time') }}</label>
              <input id="editNoticeEnd" v-model="editEnd" type="datetime-local" class="form-control" required />
            </div>
          </div>
          <p v-if="editError" class="form-error">{{ editError }}</p>
          <div class="modal-actions">
            <UiButton variant="secondary" type="button" @click="closeEditModal">{{ t('notices.actions.cancel') }}</UiButton>
            <UiButton variant="primary" type="submit">{{ t('notices.actions.save') }}</UiButton>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showDeleteModal" class="modal-overlay" @click.self="closeDeleteModal">
      <div class="modal">
        <header class="modal-header">
          <h2>{{ t('notices.delete.title') }}</h2>
          <button class="icon-button" type="button" @click="closeDeleteModal" aria-label="Close">
            <i class="bi bi-x-lg"></i>
          </button>
        </header>
        <div class="modal-body">
          <p class="delete-message">{{ t('notices.delete.confirmation') }}</p>
          <p v-if="deleteError" class="form-error">{{ deleteError }}</p>
          <div class="modal-actions">
            <UiButton variant="secondary" type="button" @click="closeDeleteModal">{{ t('notices.actions.cancel') }}</UiButton>
            <UiButton variant="danger" type="button" @click="confirmDelete">{{ t('notices.actions.delete') }}</UiButton>
          </div>
        </div>
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

.notice-preview-banner {
  margin-top: 0.25rem;
  border-radius: 10px;
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

.notice-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
  margin-left: auto;
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

  .notice-actions {
    width: 100%;
    justify-content: flex-end;
    margin-left: 0;
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

.markdown-legend {
  margin-top: 0.5rem;
  border: 1px dashed var(--border-default);
  border-radius: 8px;
  padding: 0.5rem 0.7rem;
  color: var(--text-secondary);
  background: var(--bg-card);
}

.markdown-legend summary {
  cursor: pointer;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-secondary);
}

.markdown-legend[open] summary {
  color: var(--text-primary);
}

.markdown-legend-body {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  margin-top: 0.5rem;
}

.markdown-legend-row {
  display: flex;
  justify-content: space-between;
  gap: 0.75rem;
  font-size: 0.85rem;
}

.markdown-legend-label {
  font-weight: 600;
  color: var(--text-secondary);
}

.markdown-legend-example {
  font-family: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono',
    'Courier New', monospace;
  color: var(--text-primary);
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

.notice-preview-body {
  color: var(--text-primary);
  font-size: 0.9rem;
  line-height: 1.4;
  min-height: 1.25rem;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.6rem;
}

.delete-message {
  margin: 0;
  font-size: 0.9rem;
  color: var(--text-secondary);
}
</style>
