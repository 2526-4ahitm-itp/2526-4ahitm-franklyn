<script setup lang="ts"></script>

<template>
  <div class="wrapper">
    <div class="content">
      <span class="code">403</span>
      <div class="text">
        <h1 class="title">Access Denied</h1>
        <span class="message">Only teachers are allowed to access this page.</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wrapper {
  height: 100svh;
  width: 100vw;
  display: grid;
  place-items: center;

  font-family: Arial, Helvetica, sans-serif;
}

.content {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.code {
  font-size: 5rem;
  font-family: monospace;
}

.text .title {
  font-size: 2.4rem;
  margin-top: 0;
  margin-bottom: 0.4rem;
  text-box: trim cap;
}
</style>
