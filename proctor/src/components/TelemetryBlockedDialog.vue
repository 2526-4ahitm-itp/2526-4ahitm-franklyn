<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import UiDialog from './ui/Dialog.vue'
import UiButton from './ui/Button.vue'
import { detectTelemetryBlocked } from '@/services/telemetryBlock'

defineOptions({
  name: 'TelemetryBlockedDialog',
})

const open = defineModel<boolean>('open', { required: true })

const emit = defineEmits<{
  (e: 'dismiss-forever' | 'recheck-passed'): void
}>()

const { t } = useI18n()

type RecheckState = 'idle' | 'still-blocked' | 'passed'

const rechecking = ref(false)
const recheckState = ref<RecheckState>('idle')

function keepBlocker(): void {
  emit('dismiss-forever')
  open.value = false
}

async function iDisabledIt(): Promise<void> {
  rechecking.value = true
  recheckState.value = 'idle'
  try {
    const result = await detectTelemetryBlocked()
    if (result === 'blocked') {
      recheckState.value = 'still-blocked'
      return
    }
    // 'ok' or 'offline' — telemetry is no longer being blocked; thank the user briefly.
    recheckState.value = 'passed'
    setTimeout(() => {
      emit('recheck-passed')
      open.value = false
    }, 1200)
  } finally {
    rechecking.value = false
  }
}
</script>

<template>
  <UiDialog v-model:open="open" :title="t('telemetryBlocked.title')">
    <p class="dialog-description">{{ t('telemetryBlocked.body') }}</p>

    <p v-if="recheckState === 'still-blocked'" class="recheck recheck-error" role="alert">
      {{ t('telemetryBlocked.stillBlocked') }}
    </p>
    <p v-else-if="recheckState === 'passed'" class="recheck recheck-success" role="status">
      {{ t('telemetryBlocked.nowWorking') }}
    </p>

    <div class="modal-actions">
      <UiButton variant="secondary" :disabled="rechecking" @click="keepBlocker">
        {{ t('telemetryBlocked.keepBlocker') }}
      </UiButton>
      <UiButton variant="primary" :loading="rechecking" @click="iDisabledIt">
        {{ t('telemetryBlocked.iDisabledIt') }}
      </UiButton>
    </div>
  </UiDialog>
</template>

<style scoped>
.dialog-description {
  font-size: 0.9rem;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: var(--space-4);
}

.recheck {
  font-size: 0.85rem;
  line-height: 1.4;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  margin-bottom: var(--space-4);
}

.recheck-error {
  color: var(--error);
  background: var(--alert-error-bg);
}

.recheck-success {
  color: var(--success);
  background: var(--alert-success-bg);
}

.modal-actions {
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
  margin-top: var(--space-5);
}
</style>
