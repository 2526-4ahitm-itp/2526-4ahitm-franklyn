import { defineStore } from 'pinia'
import { ref } from 'vue'

export type Theme = 'LIGHT' | 'DARK' | 'SYSTEM'

export const useThemeStore = defineStore(
  'theme',
  () => {
    const theme = ref<Theme>('SYSTEM')

    function setTheme(newTheme: Theme) {
      theme.value = newTheme
    }

    return { theme, setTheme }
  },
  {
    persist: true,
  },
)
