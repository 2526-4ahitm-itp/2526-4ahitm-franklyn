<script setup lang="ts">
import { computed, watch } from 'vue'
import NavComponent from './components/NavComponent.vue'
import NoticeBanner from '@/components/notice/NoticeBanner.vue'
import { useResolvedTheme } from '@/services/theme'
import { useCurrentUser } from '@/services/user'
import { useNotices } from '@/services/notices'
import { useDismissedNotices } from '@/services/dismissedNotices'
import type { Notice, NoticeType } from '@/types/Notice'
import { useI18n } from 'vue-i18n'
import { toDate } from '@/lib/datetime'
import { renderNoticeMarkdown } from '@/utils/noticeMarkdown'

// Centralized theme resolution
useResolvedTheme()

const { data: user } = useCurrentUser()
const { data: noticesData } = useNotices()
const { dismissedSingleIds, dismissedTimedIds, dismissSingle, dismissTimed } = useDismissedNotices()
const { locale } = useI18n()

const noticeOrder: Record<NoticeType, number> = {
  ALERT: 0,
  TIMED: 1,
  SINGLE: 2,
}

const notices = computed<Notice[]>(() => noticesData.value ?? [])

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

function dismissNotice(notice: Notice) {
  if (notice.type === 'ALERT') return
  if (notice.type === 'TIMED') {
    dismissTimed(notice.id)
    return
  }
  dismissSingle(notice.id)
}

watch(
  () => user.value,
  (next) => {
    if (!next) return
    if (next.language) locale.value = next.language
  },
  { immediate: true },
)
</script>

<template>
  <div class="app-shell">
    <transition-group
      v-if="activeNotices.length"
      name="notice-slide"
      tag="div"
      class="notice-stack"
    >
      <NoticeBanner
        v-for="notice in activeNotices"
        :key="notice.id"
        :type="notice.type"
        :content-html="renderNoticeMarkdown(notice.content)"
        :dismissible="notice.type !== 'ALERT'"
        @dismiss="dismissNotice(notice)"
      />
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

.notice-slide-enter-active,
.notice-slide-leave-active {
  transition:
    opacity 0.2s ease,
    transform 0.2s ease;
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
</style>
