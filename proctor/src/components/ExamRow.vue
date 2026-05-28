<script setup lang="ts">
import type { Exam } from '@/types/Exam'
import { useI18n } from 'vue-i18n'
import { getExamStatus, examStatusTranslated } from '@/lib/examStatus'
import { formatExamRange } from '@/lib/datetime'
import UiBadge from '@/components/ui/Badge.vue'

defineOptions({
  name: 'ExamRow',
})

interface Props {
  exam: Exam
}

defineProps<Props>()

const { t } = useI18n()
</script>

<template>
  <div class="exam-row" role="button" tabindex="0">
    <div class="exam-row-content">
      <div class="exam-details">
        <div class="exam-title-row">
          <h3 class="exam-name">{{ exam.title || t('exams.untitled') }}</h3>
        </div>
        <div class="exam-meta-row">
          <span class="exam-meta exam-meta-pin">PIN {{ exam.pin || t('common.none') }}</span>
          <span class="exam-meta-separator">·</span>
          <span class="exam-meta">{{ formatExamRange(exam.startTime, exam.endTime) }}</span>
        </div>
      </div>
      <div class="exam-status-badge">
        <UiBadge :variant="getExamStatus(exam.startedAt, exam.endedAt)">
          {{ examStatusTranslated(getExamStatus(exam.startedAt, exam.endedAt)) }}
        </UiBadge>
      </div>
    </div>
  </div>
</template>

<style scoped>
.exam-row {
  background: var(--bg-card);
  padding: var(--space-5) var(--space-6);
  border-radius: var(--radius-xl);
  border: 1px solid var(--border-default);
  cursor: pointer;
  transition: border-color 0.15s ease;
}

.exam-row:hover {
  border-color: var(--primary);
}

.exam-row:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.exam-row-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.exam-details {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.exam-title-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.exam-name {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-primary);
}

.exam-meta-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.exam-meta-separator {
  color: var(--text-tertiary);
}

.exam-meta-pin {
  font-family: var(--font-mono);
}

</style>
