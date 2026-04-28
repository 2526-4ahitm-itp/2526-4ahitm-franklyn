<script setup lang="ts">
import {computed, onMounted, ref, watch} from 'vue'
import { storeToRefs } from 'pinia'
import UiButton from '@/components/ui/Button.vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import { type Theme, useThemeStore } from '@/stores/ThemeStore'
import {useUserStore} from "@/stores/UserStore.ts";

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore
const keycloakStore = useKeycloakStore()
const userStore = useUserStore();
const { updateSettings } = userStore;
const selectedLanguage = ref(userStore.language)


onMounted( () => {
  void userStore.init()
})
watch(() => userStore.language, (lang) => {
  if (lang) {
    console.warn('language updated:', lang)
    selectedLanguage.value = userStore.language
  }
})

const themeOptions: { value: Theme; label: string; icon: string }[] = [
  { value: 'light', label: 'Light', icon: 'bi bi-sun' },
  { value: 'dark', label: 'Dark', icon: 'bi bi-moon' },
  { value: 'system', label: 'System', icon: 'bi bi-display' },
]

const languageOptions = [
  { value: 'en', label: 'English' },
  { value: 'de', label: 'German' },
  { value: 'at', label: 'Austrian German' },
]

function selectTheme(newTheme: Theme): void {
  setTheme(newTheme)
}
async function updateUserSettings(newLanguage: string) : Promise<void> {
  await updateSettings(newLanguage)
}

const userClaims = computed(() => keycloakStore.keycloak.tokenParsed)

const accountUsername = computed(() => {
  const username = userClaims.value?.preferred_username
  const displayName = userClaims.value?.name

  if (typeof username === 'string' && username.length > 0) {
    return username
  }

  if (typeof displayName === 'string' && displayName.length > 0) {
    return displayName
  }

  return 'Unavailable'
})

const accountEmail = computed(() => {
  const email = userClaims.value?.email
  return typeof email === 'string' && email.length > 0 ? email : 'Unavailable'
})

const accountRole = computed(() => {
  const isAdmin = keycloakStore.keycloak.realmAccess?.roles.includes('franklyn-admin')
  const isTeacher = userClaims.value?.distinguished_name?.includes('OU=Teacher')

  if (isAdmin) {
    return 'Admin'
  }

  if (isTeacher) {
    return 'Teacher'
  }

  return 'User'
})

const accountInitials = computed(() => {
  const displayName = userClaims.value?.name

  if (typeof displayName === 'string' && displayName.trim().length > 0) {
    const parts = displayName
      .trim()
      .split(/\s+/)
      .filter((part) => part.length > 0)

    if (parts.length >= 2) {
      const first = parts[0]
      const second = parts[1]

      if (first && second) {
        return `${first.charAt(0)}${second.charAt(0)}`.toUpperCase()
      }
    }

    if (parts.length === 1) {
      const onlyPart = parts[0]

      if (onlyPart) {
        return onlyPart.slice(0, 2).toUpperCase()
      }
    }
  }

  const username = userClaims.value?.preferred_username

  if (typeof username === 'string' && username.trim().length > 0) {
    return username.trim().slice(0, 2).toUpperCase()
  }

  return 'NA'
})

async function logout(): Promise<void> {
  await keycloakStore.keycloak.logout()
}
</script>

<template>
  <main class="settings-view">
    <header class="settings-header">
      <h1>Settings</h1>
      <p>Keep your workspace clear and comfortable.</p>
    </header>

    <section class="settings-section">
      <h2>Appearance</h2>
      <div class="chip-list" role="radiogroup" aria-label="Theme">
        <button
          v-for="option in themeOptions"
          :key="option.value"
          :class="['chip-button', { 'chip-button--active': theme === option.value }]"
          type="button"
          role="radio"
          :aria-checked="theme === option.value"
          @click="selectTheme(option.value); updateUserSettings(selectedLanguage!)"
        >
          <i :class="option.icon"></i>
          <span>{{ option.label }}</span>
        </button>
      </div>
    </section>

    <section class="settings-section">
      <h2>Language</h2>
      <div class="choice-list" role="radiogroup" aria-label="Language">
        <label v-for="option in languageOptions" :key="option.value" class="choice-row" @click="updateUserSettings(option.value)">
          <input v-model="selectedLanguage" type="radio" name="language" :value="option.value"/>
          <span>{{ option.label }}</span>
        </label>
      </div>
    </section>

    <section class="settings-section">
      <div class="account-header">
        <span class="account-avatar" aria-hidden="true">{{ accountInitials }}</span>
        <h2>Account</h2>
      </div>
      <dl class="account-grid">
        <div>
          <dt>Username</dt>
          <dd>{{ accountUsername }}</dd>
        </div>
        <div>
          <dt>Email</dt>
          <dd>{{ accountEmail }}</dd>
        </div>
        <div>
          <dt>Role</dt>
          <dd>{{ accountRole }}</dd>
        </div>
      </dl>
      <UiButton variant="danger" @click="logout">Log out</UiButton>
    </section>
  </main>
</template>

<style scoped>
.settings-view {
  width: min(92%, 760px);
  margin: 0 auto;
  padding: 2.25rem 0 3rem;
  color: var(--text-primary);
}

.settings-header {
  margin-bottom: 1.5rem;
}

.settings-header h1 {
  margin: 0;
  font-size: clamp(1.5rem, 1.8vw, 1.95rem);
  font-weight: 630;
}

.settings-header p {
  margin: 0.35rem 0 0;
  color: var(--text-secondary);
  font-size: 0.95rem;
}

.settings-section {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: 12px;
  padding: 1rem;
}

.settings-section + .settings-section {
  margin-top: 0.9rem;
}

.settings-section h2 {
  margin: 0 0 0.8rem;
  font-size: 1rem;
  font-weight: 600;
}

.account-header {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 0.8rem;
}

.account-header h2 {
  margin: 0;
}

.account-avatar {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 650;
  letter-spacing: 0.03em;
  background: var(--bg-subtle);
  border: 1px solid var(--border-default);
  color: var(--text-primary);
  user-select: none;
}

.chip-list {
  display: flex;
  gap: 0.55rem;
  flex-wrap: wrap;
}

.chip-button {
  border: 1px solid var(--border-default);
  background: var(--bg-input);
  color: var(--text-primary);
  border-radius: 999px;
  padding: 0.48rem 0.85rem;
  min-height: 2.2rem;
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  cursor: pointer;
  transition: border-color 0.18s ease, background-color 0.18s ease;
}

.chip-button:hover {
  border-color: var(--border-strong);
}

.chip-button--active {
  background: var(--primary);
  border-color: var(--primary);
  color: #fff;
}

.choice-list {
  display: grid;
  gap: 0.55rem;
}

.choice-row {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  color: var(--text-primary);
}

.choice-row input {
  accent-color: var(--primary);
}

.account-grid {
  margin: 0 0 0.9rem;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.8rem;
}

.account-grid dt {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.82rem;
}

.account-grid dd {
  margin: 0.28rem 0 0;
  color: var(--text-primary);
  font-weight: 500;
}

@media (max-width: 720px) {
  .settings-view {
    width: min(94%, 760px);
    padding-top: 1.2rem;
  }

  .settings-section {
    padding: 0.9rem;
  }

  .account-grid {
    grid-template-columns: 1fr;
    gap: 0.65rem;
  }
}
</style>
