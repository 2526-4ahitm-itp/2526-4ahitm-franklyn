<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import UiButton from './ui/Button.vue'

defineOptions({
  name: 'ExpandedSentinelOverlay',
})

interface Props {
  sentinelName: string
  frameData?: string | null
}

defineProps<Props>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()
</script>

<template>
  <div v-if="open" class="overlay" @click.self="open = false">
    <div class="overlay-content">
      <UiButton
        class="overlay-close"
        variant="secondary"
        :aria-label="t('proctoring.close_expanded')"
        @click="open = false"
      >
        &times;
      </UiButton>
      <img
        v-if="frameData"
        :src="'data:image/jpeg;base64,' + frameData"
        :alt="`Sentinel ${sentinelName} frame`"
      />
      <div v-else class="frame-placeholder">{{ t('proctoring.waiting') }}</div>
      <p class="overlay-label">{{ sentinelName }}</p>
    </div>
  </div>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
}

.overlay-content {
  position: relative;
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: var(--space-4);
  width: 80vw;
  height: 80vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
}

.overlay-content img {
  width: 100%;
  height: 100%;
  border-radius: var(--radius-sm);
  object-fit: contain;
  flex: 1;
  min-height: 0;
}

.frame-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.95rem;
  padding: 0.75rem 0.5rem;
  border-radius: var(--radius-sm);
  background: var(--bg-card);
  width: 100%;
  aspect-ratio: 16 / 9;
}

.overlay-close.button {
  position: absolute;
  top: var(--space-1);
  right: var(--space-2);
  min-height: 0;
  min-width: 0;
  padding: var(--space-1) var(--space-2);
  font-size: 1.5rem;
  line-height: 1;
  color: var(--text-secondary);
}

.overlay-label {
  font-size: 1.1rem;
  text-align: center;
}
</style>
