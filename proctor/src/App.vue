<script setup lang="ts">
import {computed, onMounted, ref, watch} from 'vue'
import NavComponent from './components/NavComponent.vue'
import NoticeBanner from '@/components/notice/NoticeBanner.vue'
import { useThemeStore } from '@/stores/ThemeStore'
import {useUserStore} from "@/stores/UserStore.ts";
import {storeToRefs} from "pinia";
import { useNoticeStore } from './stores/NoticeStore'
import type { Notice, NoticeType } from '@/types/Notice'
import { renderNoticeMarkdown } from '@/utils/noticeMarkdown'
import {useI18n} from "vue-i18n";

const userStore = useUserStore();
const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore
const noticeStore = useNoticeStore()
const { notices } = storeToRefs(noticeStore)
const { fetchNotices } = noticeStore
const { locale } = useI18n()
const selectedLanguage = ref(userStore.language)


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
  void userStore.init()
  setTheme(theme.value)
  if(selectedLanguage.value) {
    locale.value = selectedLanguage.value;
  }
})
watch(
  () => userStore.language,
  (lang) => {
    if (lang) {
      selectedLanguage.value = userStore.language
      if (selectedLanguage.value) {
        locale.value = selectedLanguage.value;
      }
    }
  },
)
</script>

<template>
  <div class="app-shell">
    <transition-group v-if="activeNotices.length" name="notice-slide" tag="div" class="notice-stack">
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
</style>
