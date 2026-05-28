<script setup lang="ts">
import { useI18n } from 'vue-i18n'

defineOptions({
  name: 'ExamStatusFilter',
})

const filter = defineModel<'all' | 'live' | 'scheduled' | 'completed'>({ required: true })

const { t } = useI18n()
</script>

<template>
  <div class="filter-pills">
    <button
      class="filter-pill"
      :class="{ active: filter === 'all' }"
      @click="filter = 'all'"
      @keydown.enter="filter = 'all'"
      @keydown.space.prevent="filter = 'all'"
      tabindex="0"
      role="tab"
      :aria-selected="filter === 'all'"
    >
      {{ t('exams.all') }}
    </button>
    <button
      class="filter-pill status-live"
      :class="{ active: filter === 'live' }"
      @click="filter = 'live'"
      @keydown.enter="filter = 'live'"
      @keydown.space.prevent="filter = 'live'"
      tabindex="0"
      role="tab"
      :aria-selected="filter === 'live'"
    >
      {{ t('exams.live') }}
    </button>
    <button
      class="filter-pill status-scheduled"
      :class="{ active: filter === 'scheduled' }"
      @click="filter = 'scheduled'"
      @keydown.enter="filter = 'scheduled'"
      @keydown.space.prevent="filter = 'scheduled'"
      tabindex="0"
      role="tab"
      :aria-selected="filter === 'scheduled'"
    >
      {{ t('exams.scheduled') }}
    </button>
    <button
      class="filter-pill status-completed"
      :class="{ active: filter === 'completed' }"
      @click="filter = 'completed'"
      @keydown.enter="filter = 'completed'"
      @keydown.space.prevent="filter = 'completed'"
      tabindex="0"
      role="tab"
      :aria-selected="filter === 'completed'"
    >
      {{ t('exams.completed') }}
    </button>
  </div>
</template>

<style scoped>
.filter-pills {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-6);
}

.filter-pill {
  padding: var(--space-2) var(--space-4);
  border-radius: var(--radius-pill);
  font-size: 0.85rem;
  font-weight: 600;
  border: none;
  background: var(--bg-card);
  color: var(--text-secondary);
  cursor: pointer;
  box-shadow: inset 0 0 0 2px transparent;
  transition:
    color 0.2s ease,
    background-color 0.2s ease,
    box-shadow 0.2s ease;
}

.filter-pill:hover {
  background: var(--border-default);
  color: var(--text-primary);
}

.filter-pill:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.filter-pill.active {
  box-shadow: inset 0 0 0 2px var(--primary);
  color: var(--primary);
  background: transparent;
}

.filter-pill.active.status-live {
  box-shadow: inset 0 0 0 2px var(--status-live);
  color: var(--status-live);
}

.filter-pill.active.status-scheduled {
  box-shadow: inset 0 0 0 2px var(--status-scheduled);
  color: var(--status-scheduled);
}

.filter-pill.active.status-completed {
  box-shadow: inset 0 0 0 2px var(--status-completed);
  color: var(--status-completed);
}
</style>
