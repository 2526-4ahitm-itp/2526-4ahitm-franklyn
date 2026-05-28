<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import UiDialog from './ui/Dialog.vue'
import UiButton from './ui/Button.vue'

defineOptions({
  name: 'NewExamDialog',
})

interface Props {
  isEdit?: boolean
  initialValues?: {
    title?: string
    date?: string
    startTime?: string
    endTime?: string
  }
}

const props = withDefaults(defineProps<Props>(), {
  isEdit: false,
  initialValues: () => ({
    title: '',
    date: '',
    startTime: '',
    endTime: '',
  }),
})

const open = defineModel<boolean>('open', { required: true })

const emit = defineEmits<{
  (
    e: 'submit',
    payload: { title?: string; date: string; startTime: string; endTime: string }
  ): void
}>()

const { t } = useI18n()

const titleVal = ref('')
const dateVal = ref('')
const startTimeVal = ref('')
const endTimeVal = ref('')

// Initialize or update fields when modal opens or props change
watch(
  [open, () => props.initialValues],
  () => {
    if (open.value) {
      titleVal.value = props.initialValues.title ?? ''
      dateVal.value = props.initialValues.date ?? ''
      startTimeVal.value = props.initialValues.startTime ?? ''
      endTimeVal.value = props.initialValues.endTime ?? ''
    }
  },
  { immediate: true }
)

function handleSubmit() {
  if (!dateVal.value || !startTimeVal.value || !endTimeVal.value) {
    return
  }
  if (!props.isEdit && !titleVal.value.trim()) {
    return
  }

  emit('submit', {
    title: props.isEdit ? undefined : titleVal.value,
    date: dateVal.value,
    startTime: startTimeVal.value,
    endTime: endTimeVal.value,
  })
}
</script>

<template>
  <UiDialog v-model:open="open" :title="isEdit ? t('detail.edit_exam') : t('exams.wizard.new')">
    <form @submit.prevent="handleSubmit">
      <div v-if="!isEdit" class="form-group">
        <label for="examTitle">{{ t('exams.wizard.title') }}</label>
        <input id="examTitle" type="text" v-model="titleVal" required />
      </div>
      <div class="form-group">
        <label for="examDate">{{ t('exams.wizard.date') }}</label>
        <input id="examDate" type="date" v-model="dateVal" required />
      </div>
      <div class="form-row">
        <div class="form-group">
          <label for="examStartTime">{{ t('exams.wizard.start_time') }}</label>
          <input id="examStartTime" type="time" v-model="startTimeVal" required />
        </div>
        <div class="form-group">
          <label for="examEndTime">{{ t('exams.wizard.end_time') }}</label>
          <input id="examEndTime" type="time" v-model="endTimeVal" required />
        </div>
      </div>
      <div class="modal-actions">
        <UiButton variant="secondary" @click="open = false">
          {{ t('exams.wizard.cancel') }}
        </UiButton>
        <UiButton
          variant="primary"
          type="submit"
          :disabled="(!isEdit && !titleVal.trim()) || !dateVal || !startTimeVal || !endTimeVal"
        >
          {{ isEdit ? t('detail.save') : t('exams.wizard.create') }}
        </UiButton>
      </div>
    </form>
  </UiDialog>
</template>

<style scoped>
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
</style>
