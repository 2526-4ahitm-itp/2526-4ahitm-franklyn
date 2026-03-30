<script setup lang="ts">
import { useThemeStore, type Theme } from '@/stores/ThemeStore'
import { storeToRefs } from 'pinia'
import { ref } from 'vue'

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore

const isOpen = ref(false)

function selectTheme(newTheme: Theme) {
  setTheme(newTheme)
  isOpen.value = false
}
</script>

<template>
  <div class="theme-switcher-container">
    <button @click="isOpen = !isOpen" class="theme-switcher-btn">
      <span v-if="theme === 'light'">
        <i class="bi bi-sun"></i>
      </span>
      <span v-else-if="theme === 'dark'">
        <i class="bi bi-moon"></i>
      </span>
      <span v-else>
        <i class="bi bi-display"></i>
      </span>
      <i class="bi bi-chevron-down chevron"></i>
    </button>
    <div v-if="isOpen" class="dropdown-menu">
      <button @click="selectTheme('light')" :class="{ active: theme === 'light' }">
        <i class="bi bi-sun"></i> Light
      </button>
      <button @click="selectTheme('dark')" :class="{ active: theme === 'dark' }">
        <i class="bi bi-moon"></i> Dark
      </button>
      <button @click="selectTheme('system')" :class="{ active: theme === 'system' }">
        <i class="bi bi-display"></i> System
      </button>
    </div>
  </div>
</template>

<style scoped>
.theme-switcher-container {
  position: relative;
}

.theme-switcher-btn {
  background: transparent;
  border: 1px solid hsla(0, 0%, 100%, 0.7);
  color: white;
  border-radius: 5px;
  padding: 0.45rem 0.8rem;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.theme-switcher-btn .chevron {
  font-size: 0.7rem;
}

.theme-switcher-btn:hover {
  background: hsla(0, 0%, 100%, 0.15);
  border-color: #fff;
}

.dropdown-menu {
  position: absolute;
  top: 120%;
  right: 0;
  background: var(--bg-modal);
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 8px;
  width: 160px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.dropdown-menu button {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.95rem;
  font-weight: 500;
}

.dropdown-menu button:hover {
  background: var(--bg-input);
  color: var(--text-primary);
}

.dropdown-menu button.active {
  background: var(--primary);
  color: white;
}
</style>
