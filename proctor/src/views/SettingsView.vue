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


    <h3>Language</h3>
    <div class="apperance-possibilities">
      <div class="single-mode">
    <input type="radio" name="language" id="english">
    <label for="english">English</label>
      </div>
      <div class="single-mode">
    <input type="radio" name="language" id="german">
    <label for="english">German</label>
      </div>
      <div class="single-mode">
    <input type="radio" name="language" id="austrian">
    <label for="english">Austrian</label>
      </div>
    </div>


    <h3>Accountdetails</h3>
    <div class="account-details">
      <div class="user-flex">
    <div class="user-field">
      <h3>Username</h3>
      <h4>Erich Baar</h4>
    </div>
      <div class="user-field">
        <h3>Email</h3>
        <h4>Erich Baar</h4>
      </div>
      <div class="user-field">
        <h3>Role</h3>
        <h4>Erich Baar</h4>
      </div>
        </div>
    <div class="logout-button">
      <button>Logout</button>
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

.user-flex{
  width: 40vw;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  flex-wrap: wrap;
}

.user-field{
  width: 20vw;
}

.user-field h3{
margin-bottom: 0.5vh;
  margin-top: 0.2vh;
}

.user-field h4{
  margin-top: 0.3vh;
}
</style>
