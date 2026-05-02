<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import NavComponent from './components/NavComponent.vue'
import { useThemeStore } from './stores/ThemeStore'
import { useNoticeStore } from './stores/NoticeStore'
import type { Notice, NoticeType } from '@/types/Notice'

useThemeStore()

const noticeStore = useNoticeStore()
const { notices } = storeToRefs(noticeStore)
const { fetchNotices } = noticeStore

const dismissedSingleIds = ref<Set<string>>(new Set())
const dismissedTimedIds = ref<Set<string>>(new Set())

const noticeOrder: Record<NoticeType, number> = {
  ALERT: 0,
  TIMED: 1,
  SINGLE: 2,
}

const activeNotices = computed(() => {
  const now = Date.now()
  const storedSingles = dismissedSingleIds.value
  const dismissedTimed = dismissedTimedIds.value

  return notices.value
    .filter((notice) => {
      if (notice.type === 'SINGLE' && storedSingles.has(notice.id)) return false
      if (notice.type === 'TIMED' && dismissedTimed.has(notice.id)) return false
      if (notice.type === 'TIMED') {
        const start = toDate(notice.startTime)
        const end = toDate(notice.endTime)
        if (!start || !end) return false
        return start.getTime() <= now && now <= end.getTime()
      }
      return true
    })
    .sort((a, b) => {
      const order = noticeOrder[a.type] - noticeOrder[b.type]
      if (order !== 0) return order
      const aStart = toDate(a.startTime)?.getTime() ?? 0
      const bStart = toDate(b.startTime)?.getTime() ?? 0
      return bStart - aStart
    })
})

function toDate(value: Date | string | null): Date | null {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return isNaN(date.getTime()) ? null : date
}

function loadDismissedNotices() {
  try {
    const raw = localStorage.getItem('franklyn.notice.dismissed')
    if (!raw) return
    const parsed = JSON.parse(raw)
    if (Array.isArray(parsed)) {
        dismissedSingleIds.value = new Set(parsed.filter((id) => typeof id === 'string'))
    }
  } catch (err) {
    console.error('Failed to load dismissed notices', err)
  }
}

function dismissNotice(notice: Notice) {
  if (notice.type === 'ALERT') return

  if (notice.type === 'TIMED') {
    const nextTimed = new Set(dismissedTimedIds.value)
    nextTimed.add(notice.id)
    dismissedTimedIds.value = nextTimed
    return
  }

  const nextStored = new Set(dismissedSingleIds.value)
  nextStored.add(notice.id)
  dismissedSingleIds.value = nextStored
  localStorage.setItem('franklyn.notice.dismissed', JSON.stringify([...nextStored]))
}

onMounted(() => {
  loadDismissedNotices()
  void fetchNotices()
})
</script>

<template>
  <div class="app-shell">
    <transition-group v-if="activeNotices.length" name="notice-slide" tag="div" class="notice-stack">
      <section
        v-for="notice in activeNotices"
        :key="notice.id"
        class="notice-banner"
        :class="`notice-${notice.type.toLowerCase()}`"
        :role="notice.type === 'ALERT' ? 'alert' : 'status'"
        :aria-live="notice.type === 'ALERT' ? 'assertive' : 'polite'"
      >
        <div class="notice-inner">
          <div class="notice-content">
            <p class="notice-text">{{ notice.content }}</p>
          </div>
        </div>
        <button
          class="notice-dismiss"
          type="button"
          :disabled="notice.type === 'ALERT'"
          @click="dismissNotice(notice)"
          :aria-hidden="notice.type === 'ALERT'"
          :tabindex="notice.type === 'ALERT' ? -1 : 0"
          aria-label="Dismiss notice"
        >
          <i class="bi bi-x-lg"></i>
        </button>
      </section>
    </transition-group>
    <NavComponent v-if="!$route.meta.hideNav" />
    <main class="app-main">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.app-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-main {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.notice-stack {
  display: flex;
  flex-direction: column;
  gap: 0;
  width: 100%;
  box-sizing: border-box;
}

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

.notice-slide-enter-active,
.notice-slide-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.notice-slide-enter-from,
.notice-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.notice-slide-leave-active {
  transition: none;
}

.notice-slide-leave-to {
  opacity: 1;
  transform: none;
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
