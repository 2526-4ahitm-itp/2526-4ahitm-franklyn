<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import UiButton from '@/components/ui/Button.vue'
import ThemeSwitcher from '@/components/ui/ThemeSwitcher.vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import { type Theme, useThemeStore } from '@/stores/ThemeStore'
import { useCurrentUser, useUpdateSettings, useRoles } from '@/services/user'
import { useI18n } from 'vue-i18n'

const themeStore = useThemeStore()
const { theme } = storeToRefs(themeStore)
const { setTheme } = themeStore
const keycloakStore = useKeycloakStore()
const { data: user, isLoading } = useCurrentUser()
const updateSettingsMutation = useUpdateSettings()
const { t, locale } = useI18n()

const selectedLanguage = ref(locale.value)

watch(
  () => user.value?.language,
  (nextLang) => {
    if (nextLang) {
      selectedLanguage.value = nextLang
      locale.value = nextLang
    }
  },
  { immediate: true },
)

watch(
  () => user.value?.theme,
  (nextTheme) => {
    if (nextTheme) {
      setTheme(nextTheme)
    }
  },
  { immediate: true },
)

const languageOptions = computed(() => [
  { value: 'en', label: t('settings.english') },
  { value: 'de', label: t('settings.german') },
])

async function selectTheme(newTheme: Theme): Promise<void> {
  setTheme(newTheme)
  try {
    await updateSettingsMutation.mutateAsync({
      language: selectedLanguage.value,
      theme: newTheme,
    })
  } catch (err) {
    console.error(err)
  }
}

async function selectLanguage(newLanguage: string): Promise<void> {
  selectedLanguage.value = newLanguage
  locale.value = newLanguage
  try {
    await updateSettingsMutation.mutateAsync({
      language: newLanguage,
      theme: theme.value,
    })
  } catch (err) {
    console.error(err)
  }
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

  return t('common.unavailable')
})

const accountEmail = computed(() => {
  const email = userClaims.value?.email
  return typeof email === 'string' && email.length > 0 ? email : t('common.unavailable')
})

const { isAdmin, isTeacher } = useRoles()

const accountRole = computed(() => {
  if (isAdmin.value) {
    return t('settings.role_admin')
  }

  if (isTeacher.value) {
    return t('settings.role_teacher')
  }

  return t('settings.role_user')
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
  <main v-if="isLoading" class="settings-view loading-state">
    <p>{{ t('common.loading') }}</p>
  </main>
  <main v-else class="settings-view">
    <header class="settings-header">
      <h1>{{ t('settings.settings') }}</h1>
      <p>{{ t('settings.subtitle') }}</p>
    </header>

    <section class="settings-section">
      <h2>{{ t('settings.appearance') }}</h2>
      <ThemeSwitcher @change="selectTheme" />
    </section>

    <section class="settings-section">
      <h2>{{ t('settings.language') }}</h2>
      <div class="choice-list" role="radiogroup" :aria-label="t('settings.language')">
        <label v-for="option in languageOptions" :key="option.value" class="choice-row">
          <input
            v-model="selectedLanguage"
            type="radio"
            name="language"
            :value="option.value"
            @change="selectLanguage(option.value)"
          />
          <span>{{ option.label }}</span>
        </label>
      </div>
    </section>

    <section class="settings-section">
      <div class="account-header">
        <span class="account-avatar" aria-hidden="true">{{ accountInitials }}</span>
        <h2>{{ t('settings.account') }}</h2>
      </div>
      <dl class="account-grid">
        <div>
          <dt>{{ t('settings.username') }}</dt>
          <dd>{{ accountUsername }}</dd>
        </div>
        <div>
          <dt>{{ t('common.email') }}</dt>
          <dd>{{ accountEmail }}</dd>
        </div>
        <div>
          <dt>{{ t('settings.role') }}</dt>
          <dd>{{ accountRole }}</dd>
        </div>
      </dl>
      <UiButton variant="danger" @click="logout">{{ t('settings.logout') }}</UiButton>
    </section>
  </main>
</template>

<style scoped>
.settings-view {
  width: min(95%, var(--body-base-width));
  margin: 0 auto;
  padding: var(--space-10);
  color: var(--text-primary);
}

.settings-view.loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
}

.settings-header {
  margin-bottom: var(--space-6);
}

.settings-header h1 {
  margin: 0;
  font-size: clamp(1.5rem, 1.8vw, 1.95rem);
  font-weight: 630;
}

.settings-header p {
  margin: var(--space-1) 0 0;
  color: var(--text-secondary);
  font-size: 0.95rem;
}

.settings-section {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-xl);
  padding: var(--space-4);
}

.settings-section + .settings-section {
  margin-top: var(--space-4);
}

.settings-section h2 {
  margin: 0 0 var(--space-3);
  font-size: 1rem;
  font-weight: 600;
}

.account-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.account-header h2 {
  margin: 0;
}

.account-avatar {
  width: var(--space-8);
  height: var(--space-8);
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

.choice-list {
  display: grid;
  gap: var(--space-2);
}

.choice-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--text-primary);
}

.choice-row input {
  accent-color: var(--primary);
}

.account-grid {
  margin: 0 0 var(--space-4);
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-3);
}

.account-grid dt {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.82rem;
}

.account-grid dd {
  margin: var(--space-1) 0 0;
  color: var(--text-primary);
  font-weight: 500;
}

@media (max-width: 720px) {
  .settings-view {
    padding: var(--space-5);
  }

  .settings-section {
    padding: var(--space-4);
  }

  .account-grid {
    grid-template-columns: 1fr;
    gap: var(--space-2);
  }
}
</style>
