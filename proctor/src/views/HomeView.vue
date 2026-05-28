<script setup lang="ts">
import { useExamList, useCreateExam } from '@/services/exams'
import type { Exam } from '@/types/Exam'
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import Button from '@/components/ui/Button.vue'
import { useI18n } from 'vue-i18n'

const router = useRouter()

const { data: examsData } = useExamList()
const exams = computed<Exam[]>(() => examsData.value ?? [])
const { mutateAsync: createExam } = useCreateExam()
const { t, d } = useI18n()

const showWizard = ref(false)
const newExamTitle = ref('')
const newExamDate = ref('')
const newExamStartTime = ref('')
const newExamEndTime = ref('')
const activeFilter = ref<'all' | 'live' | 'scheduled' | 'completed'>('all')

function setFilter(filter: 'all' | 'live' | 'scheduled' | 'completed') {
  activeFilter.value = filter
}

function getExamStatus(exam: Exam): 'live' | 'completed' | 'scheduled' {
  if (!exam.startedAt) return 'scheduled'
  if (!exam.endedAt) return 'live'
  return 'completed'
}

function isState(exam: Exam, filter: 'all' | 'live' | 'scheduled' | 'completed'): boolean {
  if (filter === 'all') return true
  const status = getExamStatus(exam)
  return status === filter
}

async function createFormExam() {
  const title = newExamTitle.value
  if (!title) return

  if (!newExamDate.value || !newExamStartTime.value || !newExamEndTime.value) {
    console.error('Date, start time, and end time are required')
    return
  }

  const [startHours = 0, startMinutes = 0] = newExamStartTime.value.split(':').map(Number)
  const [endHours = 0, endMinutes = 0] = newExamEndTime.value.split(':').map(Number)
  const dateParts = newExamDate.value.split('-').map(Number)

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

  createExam({
    title,
    startTime,
    endTime,
  })
    .then(async (res) => {
      if (res !== null && res !== undefined) {
        showWizard.value = false
        newExamTitle.value = ''
        newExamDate.value = ''
        newExamStartTime.value = ''
        newExamEndTime.value = ''
        await router.push('/exams/' + res.id)
      }
      // TODO: Error handling
    })
    .catch((e) => {
      console.error(e)
    })
}

function getExamTime(exam: Exam): string {
  if (exam.endTime && exam.startTime) {
    const start = new Date(exam.startTime)
    const end = new Date(exam.endTime)
    return d(start, 'short') + ' · ' + d(start, 'time') + ' – ' + d(end, 'time')
  }
  if (exam.startTime) {
    const start = new Date(exam.startTime)
    return d(start, 'short') + ' · ' + d(start, 'time')
  }
  return t('exams.not_scheduled')
}

async function goToExam(id: string) {
  await router.push('/exams/' + id)
}

</script>

<template>
  <div class="view-management">
    <div class="section-header">
      <h2>{{ t('exams.title') }}</h2>
      <Button variant="primary" @click="showWizard = true">{{ t('exams.new') }}</Button>
    </div>

    <!-- Create Exam Modal -->
    <div v-if="showWizard" class="modal-overlay" @click.self="showWizard = false">
      <div class="modal">
        <h2>{{ t('exams.wizard.new') }}</h2>
        <div class="form-group">
          <label for="examTitle">{{ t('exams.wizard.title') }}</label>
          <input id="examTitle" type="text" v-model="newExamTitle" />
        </div>
        <div class="form-group">
          <label for="examDate">{{ t('exams.wizard.date') }}</label>
          <input id="examDate" type="date" v-model="newExamDate" />
        </div>
        <div class="form-row">
          <div class="form-group">
            <label for="examStartTime">{{ t('exams.wizard.start_time') }}</label>
            <input id="examStartTime" type="time" v-model="newExamStartTime" />
          </div>
          <div class="form-group">
            <label for="examEndTime">{{ t('exams.wizard.end_time') }}</label>
            <input id="examEndTime" type="time" v-model="newExamEndTime" />
          </div>
        </div>
        <div class="modal-actions">
          <Button variant="secondary" @click="showWizard = false"
            >{{ t('exams.wizard.cancel') }}
          </Button>
          <Button variant="primary" @click="createFormExam" :disabled="!newExamTitle.trim()">
            {{ t('exams.wizard.create') }}
          </Button>
        </div>
      </div>
    </div>

    <div class="filter-pills">
      <button
        class="filter-pill"
        :class="{ active: activeFilter === 'all' }"
        @click="setFilter('all')"
        @keydown.enter="setFilter('all')"
        @keydown.space.prevent="setFilter('all')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'all'"
      >
        {{ t('exams.all') }}
      </button>
      <button
        class="filter-pill status-live"
        :class="{ active: activeFilter === 'live' }"
        @click="setFilter('live')"
        @keydown.enter="setFilter('live')"
        @keydown.space.prevent="setFilter('live')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'live'"
      >
        {{ t('exams.live') }}
      </button>
      <button
        class="filter-pill status-scheduled"
        :class="{ active: activeFilter === 'scheduled' }"
        @click="setFilter('scheduled')"
        @keydown.enter="setFilter('scheduled')"
        @keydown.space.prevent="setFilter('scheduled')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'scheduled'"
      >
        {{ t('exams.scheduled') }}
      </button>
      <button
        class="filter-pill status-completed"
        :class="{ active: activeFilter === 'completed' }"
        @click="setFilter('completed')"
        @keydown.enter="setFilter('completed')"
        @keydown.space.prevent="setFilter('completed')"
        tabindex="0"
        role="tab"
        :aria-selected="activeFilter === 'completed'"
      >
        {{ t('exams.completed') }}
      </button>
    </div>

    <div class="exam-list">
      <div
        v-for="exam in exams.filter((e) => isState(e, activeFilter))"
        :key="exam.id"
        class="exam-row"
        @click="goToExam(exam.id)"
      >
        <div class="exam-row-content">
          <div class="exam-details">
            <div class="exam-title-row">
              <h3 class="exam-name">{{ exam.title || t('exams.untitled') }}</h3>
            </div>
            <div class="exam-meta-row">
              <span class="exam-meta exam-meta-pin">PIN {{ exam.pin || t('common.none') }}</span>
              <span class="exam-meta-separator">·</span>
              <span class="exam-meta">{{ getExamTime(exam) }}</span>
            </div>
          </div>
          <div class="exam-status-badge">
            <span class="badge" :class="'status-' + getExamStatus(exam)">
              {{
                getExamStatus(exam) === 'completed'
                  ? t('exams.completed')
                  : getExamStatus(exam) === 'live'
                    ? t('exams.live')
                    : t('exams.scheduled')
              }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.view-management {
  padding: 40px;
  max-width: 1200px;
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h2 {
  color: var(--text-primary);
  margin: 0;
  font-size: 1.5rem;
}

.filter-pills {
  display: flex;
  gap: 10px;
  margin-bottom: 24px;
}

.filter-pill {
  padding: 8px 18px;
  border-radius: 20px;
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

/* Modal Styles */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
}

.modal {
  background: var(--bg-body);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 24px;
  width: 400px;
  max-width: 90vw;
}

.modal h2 {
  margin: 0 0 20px;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-primary);
}

.form-group {
  display: flex;
  flex-direction: column;
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: 6px;
}

.form-group input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--border-default);
  border-radius: 6px;
  font-size: 0.875rem;
  background: var(--bg-subtle);
  color: var(--text-primary);
  outline: none;
  transition: border-color 0.2s;
}

.form-group input:focus {
  border-color: var(--primary);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  margin-top: 20px;
}

.exam-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

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

.class-badge {
  background-color: var(--bg-input);
  color: var(--text-secondary);
  font-size: 0.75rem;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 6px;
  text-transform: uppercase;
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
