<script setup lang="ts">
import  { type Theme, useThemeStore } from '@/stores/ThemeStore.ts'
import { storeToRefs } from 'pinia'

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore

function selectTheme(newTheme: Theme) {
  setTheme(newTheme)
}
</script>


<template>
  <div class="settings-view">
    <h2>Settings</h2>
    <h3>Appearance</h3>
    <div class="apperance-possibilities">
      <div class="single-mode">
    <input @click="selectTheme('light')" :class="{ active: theme === 'light' }" type="radio" name="appearance" id="light-mode">
    <label for="light-mode" class="after-radio"> <i class="bi bi-sun"></i> Lightmode</label>
      </div>
      <div class="single-mode">
    <input @click="selectTheme('dark')" :class="{ active: theme === 'dark' }" type="radio" name="appearance" id="dark-mode">
    <label for="dark-mode" class="after-radio"> <i class="bi bi-moon"></i> Darkmode</label>
      </div>
      <div class="single-mode">
    <input @click="selectTheme('system')" :class="{ active: theme === 'system' }" type="radio" name="appearance" id="system-mode">
    <label for="system-mode" class="after-radio"> <i class="bi bi-display"></i> System</label>
      </div>
  </div>
  </div>
</template>

<style scoped>
.settings-view {
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
  padding: 40px;
  color: var(--text-primary);
}

.settings-view h2 {
  margin: 0 0 0.5rem;
}

.settings-view p {
  margin: 0;
  color: var(--text-secondary);
}

.apperance-possibilities{
  display: flex;
  flex-direction: column;
}

.single-mode{
  margin-bottom: 2vh;
}

.after-radio{
  margin-left: 1vw;
}
</style>

