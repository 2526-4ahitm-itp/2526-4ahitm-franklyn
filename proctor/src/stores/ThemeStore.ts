import { defineStore } from 'pinia'
import { ref, watch, onMounted } from 'vue'

export type Theme = 'LIGHT' | 'DARK' | 'SYSTEM'

export const useThemeStore = defineStore(
  'theme',
  () => {
    const theme = ref<Theme>('SYSTEM')

    function setTheme(newTheme: Theme) {
      theme.value = newTheme
    }

    function applyTheme() {
      const root = document.documentElement
      const isDark =
        theme.value.toLowerCase() === 'dark' ||
        (theme.value === 'SYSTEM' && window.matchMedia('(prefers-color-scheme: dark)').matches)

      if (isDark) {
        root.setAttribute('data-theme', 'DARK')
      } else {
        root.setAttribute('data-theme', 'LIGHT')
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
    persist: true,
  },
)
