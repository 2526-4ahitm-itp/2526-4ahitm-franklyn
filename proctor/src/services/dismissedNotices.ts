import { ref, type Ref } from 'vue'

interface DismissedNoticesApi {
  dismissedSingleIds: Ref<Set<string>>
  dismissedTimedIds: Ref<Set<string>>
  dismissSingle: (id: string) => void
  dismissTimed: (id: string) => void
}

const STORAGE_KEY = 'franklyn.notice.dismissed'

const dismissedSingleIds = ref<Set<string>>(loadFromStorage())
const dismissedTimedIds = ref<Set<string>>(new Set())

function loadFromStorage(): Set<string> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return new Set()
    const parsed: unknown = JSON.parse(raw)
    if (Array.isArray(parsed)) {
      return new Set(parsed.filter((id): id is string => typeof id === 'string'))
    }
    return new Set()
  } catch (err) {
    console.error('Failed to load dismissed notices', err)
    return new Set()
  }
}

function persist() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...dismissedSingleIds.value]))
  } catch (err) {
    console.error('Failed to persist dismissed notices', err)
  }
}

export function useDismissedNotices(): DismissedNoticesApi {
  function dismissSingle(id: string) {
    const next = new Set(dismissedSingleIds.value)
    next.add(id)
    dismissedSingleIds.value = next
    persist()
  }

  function dismissTimed(id: string) {
    const next = new Set(dismissedTimedIds.value)
    next.add(id)
    dismissedTimedIds.value = next
  }

  return {
    dismissedSingleIds,
    dismissedTimedIds,
    dismissSingle,
    dismissTimed,
  }
}
