import { defineStore } from 'pinia'
import { ref, watch, onMounted } from 'vue'

export type Theme = 'light' | 'dark' | 'system'

export const useThemeStore = defineStore(
  'theme',
  () => {
    const theme = ref<Theme>('system')

    function setTheme(newTheme: Theme) {
      theme.value = newTheme
    }

    function applyTheme() {
      const root = document.documentElement
      const isDark =
        theme.value === 'dark' ||
        (theme.value === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)

      if (isDark) {
        root.setAttribute('data-theme', 'dark')
      } else {
        root.setAttribute('data-theme', 'light')
      }
    }

    onMounted(() => {
      applyTheme()
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyTheme)
    })

    watch(theme, applyTheme)

    return { theme, setTheme }
  },
  {
    persist: true
  }
)

