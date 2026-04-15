<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore, type Theme } from '@/stores/ThemeStore'
import DropdownSelect, { type DropdownItem } from './DropdownSelect.vue'

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore

const themeItems: DropdownItem<Theme>[] = [
  { value: 'light', label: 'Light', icon: 'bi bi-sun' },
  { value: 'dark', label: 'Dark', icon: 'bi bi-moon' },
  { value: 'system', label: 'System', icon: 'bi bi-display' },
]

const selectedTheme = computed<Theme>({
  get: () => theme.value,
  set: (newTheme) => setTheme(newTheme),
})
</script>

<template>
  <DropdownSelect v-model="selectedTheme" :items="themeItems" />
</template>
