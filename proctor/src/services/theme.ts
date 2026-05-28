import { computed, watch, onMounted, onUnmounted, type ComputedRef } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore, type Theme } from '@/stores/ThemeStore'
import { useCurrentUser } from '@/services/user'

/**
 * Initialize theme from localStorage / prefers-color-scheme on boot
 * to avoid flashing light theme before store/app hydration.
 */
export function initTheme(): void {
  try {
    const persisted = localStorage.getItem('theme')
    let themeVal: Theme = 'SYSTEM'
    if (persisted) {
      const parsed = JSON.parse(persisted)
      if (parsed && typeof parsed.theme === 'string') {
        themeVal = parsed.theme as Theme
      }
    }
    const isDark =
      themeVal.toLowerCase() === 'dark' ||
      (themeVal === 'SYSTEM' && window.matchMedia('(prefers-color-scheme: dark)').matches)

    const root = document.documentElement
    if (isDark) {
      root.setAttribute('data-theme', 'dark')
    } else {
      root.setAttribute('data-theme', 'light')
    }
  } catch (e) {
    console.error('Failed to initialize theme from localStorage:', e)
  }
}

/**
 * Centralized theme resolution composable.
 * Resolves theme in order:
 * 1. Logged in user backend theme setting
 * 2. Local persisted theme store value
 * 3. 'SYSTEM' fallback
 */
export function useResolvedTheme(): ComputedRef<Theme> {
  const themeStore = useThemeStore()
  const { theme: localTheme } = storeToRefs(themeStore)
  const { data: user } = useCurrentUser()

  const resolvedTheme = computed<Theme>(() => {
    if (user.value?.theme) {
      return user.value.theme
    }
    return localTheme.value || 'SYSTEM'
  })

  function applyTheme(themeVal: Theme): void {
    const root = document.documentElement
    const isDark =
      themeVal.toLowerCase() === 'dark' ||
      (themeVal === 'SYSTEM' && window.matchMedia('(prefers-color-scheme: dark)').matches)

    if (isDark) {
      root.setAttribute('data-theme', 'dark')
    } else {
      root.setAttribute('data-theme', 'light')
    }
  }

  // Watch resolvedTheme and update the root DOM element attribute
  watch(
    resolvedTheme,
    (newVal) => {
      applyTheme(newVal)
    },
    { immediate: true },
  )

  // Listen to prefers-color-scheme media changes
  onMounted(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)')
    const listener = () => {
      if (resolvedTheme.value === 'SYSTEM') {
        applyTheme('SYSTEM')
      }
    }
    media.addEventListener('change', listener)
    onUnmounted(() => {
      media.removeEventListener('change', listener)
    })
  })

  return resolvedTheme
}
