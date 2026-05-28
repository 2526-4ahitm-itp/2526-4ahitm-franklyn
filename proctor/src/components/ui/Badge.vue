<script setup lang="ts">
defineOptions({
  name: 'UiBadge',
})

interface Props {
  variant: 'live' | 'scheduled' | 'completed'
}

defineProps<Props>()
</script>

<template>
  <span class="badge" :class="`badge--${variant}`">
    <slot />
  </span>
</template>

<style scoped>
.badge {
  padding: var(--space-2) var(--space-4);
  border-radius: var(--radius-lg);
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: capitalize;
  color: white;
}

.badge--live {
  background: var(--status-live);
}

.badge--scheduled {
  background: var(--status-scheduled);
}

.badge--completed {
  background: var(--status-completed);
}
</style>
