<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCreateNotice, useDeleteNotice, useNotices, useUpdateNotice } from '@/services/notices'
import { isNormalizedError } from '@/services/graphql'
import UiButton from '@/components/ui/Button.vue'
import UiDialog from '@/components/ui/Dialog.vue'
import UiBadge from '@/components/ui/Badge.vue'
import UiTextField from '@/components/ui/TextField.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { Notice, NoticeType } from '@/types/Notice'
import { toDate } from '@/lib/datetime'

defineOptions({
  name: 'AdminNoticeBannersView',
})

const { t, d } = useI18n()
const { data: noticesData, isLoading: loading, error: queryError } = useNotices()
const createNoticeMutation = useCreateNotice()
const updateNoticeMutation = useUpdateNotice()
const deleteNoticeMutation = useDeleteNotice()

const notices = computed<Notice[]>(() => noticesData.value ?? [])
const error = computed(() => {
  const err = queryError.value
  if (!err) return null
  if (isNormalizedError(err) && err.code === 'FORBIDDEN') {
    return t('admin.notices.errors.forbidden')
  }
  return err.message
})

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

function formatDate(value: Date | string | null) {
  const date = toDate(value)
  if (!date) return t('common.none')
  return d(date, 'datetime')
}

function noticeTypeToVariant(type: NoticeType): 'live' | 'scheduled' | 'completed' {
  if (type === 'ALERT') return 'live'
  if (type === 'TIMED') return 'scheduled'
  return 'completed'
}

function formatTypeLabel(type: NoticeType) {
  if (type === 'SINGLE') return t('admin.notices.types.single')
  if (type === 'TIMED') return t('admin.notices.types.timed')
  return t('admin.notices.types.alert')
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
    createError.value = t('admin.notices.errors.content_required')
    return
  }

  const startTime = noticeType.value === 'TIMED' ? parseDateTime(noticeStart.value) : null
  const endTime = noticeType.value === 'TIMED' ? parseDateTime(noticeEnd.value) : null

  if (noticeType.value === 'TIMED') {
    if (!startTime || !endTime) {
      createError.value = t('admin.notices.errors.time_range_required')
      return
    }
    if (endTime <= startTime) {
      createError.value = t('admin.notices.errors.end_after_start')
      return
    }
  }

  try {
    await createNoticeMutation.mutateAsync({
      type: noticeType.value,
      content: noticeContent.value.trim(),
      startTime,
      endTime,
    })
    closeModal()
  } catch (err) {
    console.error(err)
    createError.value = t('admin.notices.errors.create_failed')
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
    editError.value = t('admin.notices.errors.content_required')
    return
  }

  const startTime = editNoticeType.value === 'TIMED' ? parseDateTime(editStart.value) : null
  const endTime = editNoticeType.value === 'TIMED' ? parseDateTime(editEnd.value) : null

  if (editNoticeType.value === 'TIMED') {
    if (!startTime || !endTime) {
      editError.value = t('admin.notices.errors.time_range_required')
      return
    }
    if (endTime <= startTime) {
      editError.value = t('admin.notices.errors.end_after_start')
      return
    }
  }

  try {
    await updateNoticeMutation.mutateAsync({
      id: editNoticeId.value,
      content: editContent.value.trim(),
      startTime,
      endTime,
    })
    closeEditModal()
  } catch (err) {
    console.error(err)
    editError.value = t('admin.notices.errors.update_failed')
  }
}

async function confirmDelete() {
  deleteError.value = ''
  if (!deleteNoticeId.value) return
  try {
    await deleteNoticeMutation.mutateAsync(deleteNoticeId.value)
    closeDeleteModal()
  } catch (err) {
    console.error(err)
    deleteError.value = t('admin.notices.errors.delete_failed')
  }
}
</script>

<template>
  <main class="view-management">
    <div class="section-header">
      <h2>{{ t('admin.notices.title') }}</h2>
      <UiButton variant="primary" @click="showCreateModal = true">
        {{ t('admin.notices.create') }}
      </UiButton>
    </div>

    <section class="notice-section">
      <p v-if="loading && !hasNotices" class="status-message">
        {{ t('admin.notices.loading') }}
      </p>
      <p v-else-if="!hasNotices" class="status-message">{{ t('admin.notices.empty') }}</p>
      <p v-if="error" class="status-message status-error">{{ error }}</p>

      <div v-if="hasNotices" class="notice-list">
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
            <div class="notice-actions">
              <UiBadge :variant="noticeTypeToVariant(notice.type)">
                {{ formatTypeLabel(notice.type) }}
              </UiBadge>
              <UiButton variant="secondary" @click="openEditModal(notice)">
                {{ t('common.edit') }}
              </UiButton>
              <UiButton variant="danger" @click="openDeleteModal(notice.id)">
                {{ t('common.delete') }}
              </UiButton>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Create Modal -->
    <UiDialog v-model:open="showCreateModal" :title="t('admin.notices.create_title')">
      <form class="modal-body" @submit.prevent="submitNotice">
        <div class="form-group">
          <label for="noticeType">{{ t('admin.notices.fields.type') }}</label>
          <select id="noticeType" v-model="noticeType" class="form-control" required>
            <option value="ALERT">{{ t('admin.notices.types.alert') }}</option>
            <option value="TIMED">{{ t('admin.notices.types.timed') }}</option>
            <option value="SINGLE">{{ t('admin.notices.types.single') }}</option>
          </select>
        </div>
        <UiTextField
          id="noticeContent"
          v-model="noticeContent"
          multiline
          :label="t('admin.notices.fields.content')"
          rows="4"
          minlength="3"
          maxlength="4096"
          required
        />
        <div v-if="noticeType === 'TIMED'" class="form-row">
          <UiTextField
            id="noticeStart"
            v-model="noticeStart"
            type="datetime-local"
            :label="t('admin.notices.fields.start_time')"
            required
          />
          <UiTextField
            id="noticeEnd"
            v-model="noticeEnd"
            type="datetime-local"
            :label="t('admin.notices.fields.end_time')"
            required
          />
        </div>
        <p v-if="createError" class="form-error">{{ createError }}</p>
        <div class="modal-actions">
          <UiButton variant="secondary" type="button" @click="closeModal">
            {{ t('common.cancel') }}
          </UiButton>
          <UiButton variant="primary" type="submit" :disabled="!canSubmit">
            {{ t('common.create') }}
          </UiButton>
        </div>
      </form>
    </UiDialog>

    <!-- Edit Modal -->
    <UiDialog v-model:open="showEditModal" :title="t('admin.notices.edit_title')">
      <form class="modal-body" @submit.prevent="submitEdit">
        <UiTextField
          id="editNoticeType"
          :model-value="editNoticeType ? formatTypeLabel(editNoticeType) : ''"
          :label="t('admin.notices.fields.type')"
          disabled
        />
        <UiTextField
          id="editNoticeContent"
          v-model="editContent"
          multiline
          :label="t('admin.notices.fields.content')"
          rows="4"
          minlength="3"
          maxlength="4096"
          required
        />
        <div v-if="editNoticeType === 'TIMED'" class="form-row">
          <UiTextField
            id="editNoticeStart"
            v-model="editStart"
            type="datetime-local"
            :label="t('admin.notices.fields.start_time')"
            required
          />
          <UiTextField
            id="editNoticeEnd"
            v-model="editEnd"
            type="datetime-local"
            :label="t('admin.notices.fields.end_time')"
            required
          />
        </div>
        <p v-if="editError" class="form-error">{{ editError }}</p>
        <div class="modal-actions">
          <UiButton variant="secondary" type="button" @click="closeEditModal">
            {{ t('common.cancel') }}
          </UiButton>
          <UiButton variant="primary" type="submit">
            {{ t('admin.notices.save_changes') }}
          </UiButton>
        </div>
      </form>
    </UiDialog>

    <!-- Delete Modal -->
    <ConfirmDialog
      v-model:open="showDeleteModal"
      variant="danger"
      :title="t('admin.notices.delete_title')"
      :description="t('admin.notices.delete_confirmation')"
      :confirm-label="t('common.delete')"
      :cancel-label="t('common.cancel')"
      @confirm="confirmDelete"
    />
  </main>
</template>

<style scoped>
.view-management {
  padding: var(--space-10);
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
  color: var(--text-primary);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-5);
}

.section-header h2 {
  color: var(--text-primary);
  margin: 0;
  font-size: 1.5rem;
}

.notice-section {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-xl);
  padding: var(--space-4);
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
  gap: var(--space-3);
  margin-top: 1rem;
}

.notice-row {
  background: var(--bg-card);
  padding: var(--space-5) var(--space-6);
  border-radius: var(--radius-xl);
  border: 1px solid var(--border-default);
  transition: border-color 0.15s ease;
}

.notice-row:hover {
  border-color: var(--primary);
}

.notice-row-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  gap: var(--space-4);
}

.notice-details {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.notice-title-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
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
  gap: var(--space-2);
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.notice-meta-separator {
  color: var(--text-tertiary);
}

.notice-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
  margin-left: auto;
}


@media (max-width: 720px) {
  .view-management {
    padding: var(--space-5);
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

.modal-body {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
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
  border-radius: var(--radius-lg);
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
  gap: var(--space-2);
}
</style>
