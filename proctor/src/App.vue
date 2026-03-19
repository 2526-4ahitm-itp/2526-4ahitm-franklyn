<script setup lang="ts">
import NavComponent from './components/NavComponent.vue'
</script>

<template>
  <NavComponent  v-if="!$route.meta.hideNav"/>
  <RouterView />
</template>

<style scoped></style>
