<script setup lang="ts">
import NavComponent from './components/NavComponent.vue'
import { useThemeStore } from './stores/ThemeStore'

useThemeStore()
</script>

<template>
  <NavComponent v-if="!$route.meta.hideNav" />
  <RouterView />
</template>

<style scoped></style>
