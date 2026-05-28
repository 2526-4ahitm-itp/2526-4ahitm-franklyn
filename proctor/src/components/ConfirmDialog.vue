<script setup lang="ts">
import UiDialog from './ui/Dialog.vue'
import UiButton from './ui/Button.vue'

defineOptions({
  name: 'ConfirmDialog',
})

interface Props {
  title: string
  description: string
  confirmLabel?: string
  cancelLabel?: string
  variant?: 'primary' | 'secondary' | 'danger'
}

withDefaults(defineProps<Props>(), {
  confirmLabel: 'Confirm',
  cancelLabel: 'Cancel',
  variant: 'primary',
})

const open = defineModel<boolean>('open', { required: true })

const emit = defineEmits<{
  (e: 'confirm'): void
}>()

function handleConfirm(): void {
  emit('confirm')
  open.value = false
}
</script>

<template>
  <UiDialog v-model:open="open" :title="title">
    <p class="dialog-description">{{ description }}</p>
    <div class="modal-actions">
      <UiButton variant="secondary" @click="open = false">
        {{ cancelLabel }}
      </UiButton>
      <UiButton :variant="variant" @click="handleConfirm">
        {{ confirmLabel }}
      </UiButton>
    </div>
  </UiDialog>
</template>

<style scoped>
.dialog-description {
  font-size: 0.9rem;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: var(--space-6);
}

.modal-actions {
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
  margin-top: var(--space-5);
}
</style>
