// stores/useScreenStore.js
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useScreenStore = defineStore('screen', () => {
  const screensPerRow = ref(0)
  return { screensPerRow }
})
