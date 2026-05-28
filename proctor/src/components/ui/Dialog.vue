<script setup lang="ts">
import {
  DialogRoot,
  DialogPortal,
  DialogOverlay,
  DialogContent,
  DialogTitle,
} from 'reka-ui'

defineOptions({
  name: 'UiDialog',
})

interface Props {
  title?: string
}

defineProps<Props>()

const open = defineModel<boolean>('open', { required: true })
</script>

<template>
  <DialogRoot v-model:open="open">
    <DialogPortal>
      <DialogOverlay class="dialog-overlay" />
      <DialogContent class="dialog-content" v-bind="$attrs">
        <DialogTitle v-if="title" class="dialog-title">
          {{ title }}
        </DialogTitle>
        <slot />
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>

<style scoped>
.dialog-overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  z-index: var(--z-modal);
}

.dialog-content {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: var(--bg-body);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 24px;
  width: 400px;
  max-width: 90vw;
  z-index: var(--z-modal);
  box-shadow: var(--shadow-modal);
  outline: none;
}

.dialog-title {
  margin: 0 0 20px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
}
</style>
