<script setup lang="ts">
import { useExamList, useCreateExam } from '@/services/exams'
import type { Exam } from '@/types/Exam'
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import UiButton from '@/components/ui/Button.vue'
import NewExamDialog from '@/components/NewExamDialog.vue'
import ExamStatusFilter from '@/components/ExamStatusFilter.vue'
import ExamRow from '@/components/ExamRow.vue'
import { getExamStatus } from '@/lib/examStatus'
import { useI18n } from 'vue-i18n'

defineOptions({
  name: 'HomeView',
})

const router = useRouter()
const { t } = useI18n()

const { data: examsData } = useExamList()
const exams = computed<Exam[]>(() => examsData.value ?? [])
const { mutateAsync: createExam } = useCreateExam()

const showWizard = ref(false)
const activeFilter = ref<'all' | 'live' | 'scheduled' | 'completed'>('all')

function isState(exam: Exam, filter: 'all' | 'live' | 'scheduled' | 'completed'): boolean {
  if (filter === 'all') return true
  const status = getExamStatus(exam.startedAt, exam.endedAt)
  return status === filter
}

async function handleCreateSubmit(payload: {
  title?: string
  date: string
  startTime: string
  endTime: string
}): Promise<void> {
  const { title, date, startTime: sTime, endTime: eTime } = payload
  if (!title) return

  const [startHours = 0, startMinutes = 0] = sTime.split(':').map(Number)
  const [endHours = 0, endMinutes = 0] = eTime.split(':').map(Number)
  const dateParts = date.split('-').map(Number)

  const year = dateParts[0]
  const month = dateParts[1]
  const day = dateParts[2]

  if (!year || !month || !day || isNaN(year) || isNaN(month) || isNaN(day)) {
    console.error('Invalid date format')
    return
  }

  const startTime = new Date(year, month - 1, day, startHours, startMinutes, 0, 0)
  const endTime = new Date(year, month - 1, day, endHours, endMinutes, 0, 0)

  if (isNaN(startTime.getTime()) || isNaN(endTime.getTime())) {
    console.error('Invalid date values')
    return
  }

  if (endTime <= startTime) {
    console.error('End time must be after start time')
    return
  }

  try {
    const res = await createExam({
      title,
      startTime,
      endTime,
    })
    if (res !== null && res !== undefined) {
      showWizard.value = false
      await router.push('/exams/' + res.id)
    }
  } catch (e) {
    console.error(e)
  }
}

async function goToExam(id: string): Promise<void> {
  await router.push('/exams/' + id)
}
</script>

<template>
  <div class="view-management">
    <div class="section-header">
      <h2>{{ t('exams.title') }}</h2>
      <UiButton variant="primary" @click="showWizard = true">{{ t('exams.new') }}</UiButton>
    </div>

    <!-- Create Exam Modal -->
    <NewExamDialog v-model:open="showWizard" @submit="handleCreateSubmit" />

    <ExamStatusFilter v-model="activeFilter" />

    <div class="exam-list">
      <ExamRow
        v-for="exam in exams.filter((e) => isState(e, activeFilter))"
        :key="exam.id"
        :exam="exam"
        @click="goToExam(exam.id)"
      />
    </div>
  </div>
</template>

<style scoped>
.view-management {
  padding: var(--space-10);
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-5);
}

.section-header h2 {
  color: var(--text-primary);
  margin: 0;
  font-size: 1.5rem;
}

.exam-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
</style>
