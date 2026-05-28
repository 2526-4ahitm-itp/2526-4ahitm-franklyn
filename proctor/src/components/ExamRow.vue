<script setup lang="ts">
import type { Exam } from '@/types/Exam'
import { useI18n } from 'vue-i18n'
import { getExamStatus, examStatusTranslated } from '@/lib/examStatus'
import { formatExamRange } from '@/lib/datetime'

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
        <span class="badge" :class="'status-' + getExamStatus(exam.startedAt, exam.endedAt)">
          {{ examStatusTranslated(getExamStatus(exam.startedAt, exam.endedAt)) }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.exam-row {
  background: var(--bg-card);
  padding: 20px 24px;
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
  gap: 8px;
}

.exam-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
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
  gap: 8px;
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.exam-meta-separator {
  color: var(--text-tertiary);
}

.exam-meta-pin {
  font-family: var(--font-mono);
}

.badge {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  text-transform: capitalize;
}

.status-completed {
  background: var(--status-completed);
  color: white;
}

.status-live {
  background: var(--status-live);
  color: white;
}

.status-scheduled {
  background: var(--status-scheduled);
  color: white;
}
</style>
