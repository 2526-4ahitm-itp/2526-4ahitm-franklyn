<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import UiDialog from './ui/Dialog.vue'
import UiButton from './ui/Button.vue'
import UiTextField from './ui/TextField.vue'

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
  (e: 'submit', payload: { title?: string; date: string; startTime: string; endTime: string }): void
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
  { immediate: true },
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
    <form class="form-body" @submit.prevent="handleSubmit">
      <UiTextField
        v-if="!isEdit"
        id="examTitle"
        v-model="titleVal"
        :label="t('exams.wizard.title')"
        required
      />
      <UiTextField
        id="examDate"
        v-model="dateVal"
        type="date"
        :label="t('exams.wizard.date')"
        required
      />
      <div class="form-row">
        <UiTextField
          id="examStartTime"
          v-model="startTimeVal"
          type="time"
          :label="t('exams.wizard.start_time')"
          required
        />
        <UiTextField
          id="examEndTime"
          v-model="endTimeVal"
          type="time"
          :label="t('exams.wizard.end_time')"
          required
        />
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
.form-body {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
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
}
</style>
