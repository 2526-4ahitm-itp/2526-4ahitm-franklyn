<script setup lang="ts">
import type { NoticeType } from '@/types/Notice'

const props = withDefaults(
  defineProps<{
    contentHtml: string
    type: NoticeType
    dismissible?: boolean
  }>(),
  {
    dismissible: true,
  },
)

const emit = defineEmits<{
  dismiss: []
}>()

function handleDismiss() {
  if (!props.dismissible) return
  emit('dismiss')
}

const ariaRole = props.type === 'ALERT' ? 'alert' : 'status'
const ariaLive = props.type === 'ALERT' ? 'assertive' : 'polite'
</script>

<template>
  <section class="notice-banner" :class="`notice-${props.type.toLowerCase()}`" :role="ariaRole" :aria-live="ariaLive">
    <div class="notice-inner">
      <div class="notice-content">
        <p class="notice-text notice-markdown" v-safe-html="props.contentHtml"></p>
      </div>
    </div>
    <button
      class="notice-dismiss"
      type="button"
      :disabled="!props.dismissible"
      :aria-hidden="!props.dismissible"
      :tabindex="props.dismissible ? 0 : -1"
      aria-label="Dismiss notice"
      @click="handleDismiss"
    >
      <i class="bi bi-x-lg"></i>
    </button>
  </section>
</template>

<style scoped>
.notice-banner {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.2rem 0;
  border-radius: 0;
  border: 0;
  background: var(--bg-card);
  color: var(--text-primary);
  box-shadow: none;
  gap: 0.5rem;
}

.notice-inner {
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.notice-banner.notice-alert {
  background: var(--error);
  color: var(--text-primary);
}

.notice-banner.notice-timed {
  background: var(--warning);
  color: var(--text-primary);
}

.notice-banner.notice-single {
  background: var(--info);
  color: var(--text-primary);
}

.notice-content {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
  flex: 1;
  text-align: center;
  padding: 0 0.5rem;
}

.notice-text {
  margin: 0;
  font-size: 0.8rem;
  font-weight: 600;
  line-height: 1.2;
  overflow-wrap: anywhere;
}

.notice-dismiss {
  position: static;
  margin-right: 0.75rem;
  border: 0;
  background: transparent;
  color: var(--text-primary);
  width: 1.5rem;
  height: 1.5rem;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 800;
}

.notice-dismiss:hover {
  background: rgba(0, 0, 0, 0.12);
}

.notice-dismiss:disabled {
  cursor: default;
  visibility: hidden;
}

@media (max-width: 720px) {
  .notice-banner {
    padding: 0.3rem 0;
  }

  .notice-inner {
    flex-direction: column;
    align-items: flex-start;
  }

  .notice-content {
    text-align: left;
    padding: 0;
  }

  .notice-dismiss {
    margin-right: 0.5rem;
  }
}
</style>
