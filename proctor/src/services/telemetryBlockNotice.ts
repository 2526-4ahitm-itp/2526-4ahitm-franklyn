import { ref, type Ref } from 'vue'

interface TelemetryBlockNoticeApi {
  dismissedForever: Ref<boolean>
  dismissForever: () => void
}

const STORAGE_KEY = 'franklyn.telemetry.blocker-dismissed'

const dismissedForever = ref<boolean>(loadFromStorage())

function loadFromStorage(): boolean {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'true'
  } catch (err) {
    console.error('Failed to load telemetry blocker preference', err)
    return false
  }
}

function persist() {
  try {
    localStorage.setItem(STORAGE_KEY, String(dismissedForever.value))
  } catch (err) {
    console.error('Failed to persist telemetry blocker preference', err)
  }
}

export function useTelemetryBlockNotice(): TelemetryBlockNoticeApi {
  function dismissForever() {
    dismissedForever.value = true
    persist()
  }

  return {
    dismissedForever,
    dismissForever,
  }
}
