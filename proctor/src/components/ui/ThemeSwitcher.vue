<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore, type Theme } from '@/stores/ThemeStore'
import DropdownSelect, { type DropdownItem } from './DropdownSelect.vue'
import { useI18n } from 'vue-i18n'

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore
const { t } = useI18n()

const emit = defineEmits<{
  (e: 'change', theme: Theme): void
}>()

const themeItems = computed<DropdownItem<Theme>[]>(() => [
  { value: 'LIGHT', label: t('settings.light'), icon: 'bi bi-sun' },
  { value: 'DARK', label: t('settings.dark'), icon: 'bi bi-moon' },
  { value: 'SYSTEM', label: t('settings.system'), icon: 'bi bi-display' },
])

const selectedTheme = computed<Theme>({
  get: () => theme.value,
  set: (newTheme) => {
    setTheme(newTheme)
    emit('change', newTheme)
  },
})
</script>

<template>
  <DropdownSelect
    v-model="selectedTheme"
    :items="themeItems"
    :aria-label="t('settings.appearance')"
  />
</template>
