<script lang="ts" setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import { useI18n } from 'vue-i18n'
import { useRoles, useCurrentUser } from '@/services/user'
import {
  AvatarRoot,
  AvatarFallback,
  DropdownMenuRoot,
  DropdownMenuTrigger,
  DropdownMenuPortal,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
} from 'reka-ui'

defineOptions({
  name: 'NavComponent',
})

const { t } = useI18n()
const router = useRouter()
const kc = useKeycloakStore()
const { isAdmin } = useRoles()
const { data: user } = useCurrentUser()

const userInitials = computed(() => {
  const first = user.value?.givenName?.[0] ?? ''
  const last = user.value?.familyName?.[0] ?? ''
  return ((first + last).toUpperCase() || user.value?.preferredUsername?.[0]?.toUpperCase()) ?? '?'
})

const userName = computed(
  () =>
    user.value?.givenName && user.value?.familyName
      ? `${user.value.givenName} ${user.value.familyName}`
      : (user.value?.preferredUsername ?? ''),
)

async function logout() {
  await kc.keycloak.logout()
}
</script>

<template>
  <nav class="navbar">
    <div class="navbar-left">
      <RouterLink to="/" class="logo">
        <img class="logo-img" src="@/assets/img/logo.png" :alt="t('nav.logo_alt')" />
        <span class="logo-text">FRANKLYN</span>
      </RouterLink>
    </div>
    <div class="navbar-right">
      <RouterLink v-if="isAdmin" to="/admin/notices" class="nav-item">
        {{ t('nav.admin') }}
      </RouterLink>

      <DropdownMenuRoot>
        <DropdownMenuTrigger class="account-trigger" :aria-label="t('nav.open_settings')">
          <AvatarRoot class="account-avatar">
            <AvatarFallback class="account-avatar-fallback">{{ userInitials }}</AvatarFallback>
          </AvatarRoot>
          <span class="account-name">{{ userName }}</span>
          <i class="bi bi-chevron-down account-chevron"></i>
        </DropdownMenuTrigger>

        <DropdownMenuPortal>
          <DropdownMenuContent class="nav-account-menu" align="end" :side-offset="8">
            <DropdownMenuItem class="nav-account-item" @click="router.push('/settings')">
              <i class="bi bi-gear"></i>
              {{ t('nav.open_settings') }}
            </DropdownMenuItem>
            <DropdownMenuSeparator class="nav-account-separator" />
            <DropdownMenuItem class="nav-account-item nav-account-item--danger" @click="logout">
              <i class="bi bi-box-arrow-right"></i>
              {{ t('settings.logout') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenuPortal>
      </DropdownMenuRoot>
    </div>
  </nav>
</template>

<!-- Portal content teleports to document.body — scoped selectors cannot reach it.
     Vars are prefixed nav-account- to prevent global collision. -->
<style>
.nav-account-menu {
  --nav-account-bg: var(--bg-body);
  --nav-account-border: var(--border-default);
  --nav-account-item-color: var(--text-secondary);
  --nav-account-item-hover-bg: var(--bg-subtle);

  background: var(--nav-account-bg);
  border: 1px solid var(--nav-account-border);
  border-radius: var(--radius-lg);
  padding: var(--space-2);
  min-width: 180px;
  box-shadow: var(--shadow-modal);
  z-index: var(--z-modal);
}

.nav-account-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  color: var(--nav-account-item-color);
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  border: none;
  background: transparent;
  width: 100%;
  box-sizing: border-box;
  text-align: left;
  text-decoration: none;
}

.nav-account-item[data-highlighted] {
  background: var(--nav-account-item-hover-bg);
  color: var(--text-primary);
}

.nav-account-item--danger[data-highlighted] {
  background: color-mix(in srgb, var(--error, #e53e3e) 12%, transparent);
  color: var(--error, #e53e3e);
}

.nav-account-separator {
  height: 1px;
  background: var(--nav-account-border);
  margin: var(--space-1) 0;
}
</style>

<style scoped>
.navbar {
  display: flex;
  align-items: center;
  width: 100%;
  padding: var(--space-3) var(--space-6);
  background: var(--primary);
  box-sizing: border-box;
}

.navbar-left {
  flex-shrink: 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  text-decoration: none;
}

.logo-img {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-md);
  object-fit: contain;
}

.logo-text {
  font-weight: 700;
  font-size: 1.1rem;
  color: var(--nav-fg);
  letter-spacing: 0.05em;
}

.navbar-right {
  margin-left: auto;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.nav-item {
  color: var(--nav-fg);
  font-size: 0.9rem;
  font-weight: 600;
  text-decoration: none;
  padding: var(--space-2) var(--space-3);
  opacity: 0.85;
  transition: opacity 0.15s;
}

.nav-item:hover {
  opacity: 1;
}

/* Account dropdown trigger */
.account-trigger {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  border: none;
  background: transparent;
  color: var(--nav-fg);
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 500;
  opacity: 0.85;
  transition: opacity 0.15s;
  min-width: 0;
}

.account-trigger:hover {
  opacity: 1;
}

.account-trigger:focus-visible {
  outline: 2px solid color-mix(in srgb, var(--nav-fg) 75%, transparent);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

.account-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1.6rem;
  height: 1.6rem;
  border-radius: 50%;
  background: color-mix(in srgb, var(--nav-fg) 20%, transparent);
  flex-shrink: 0;
}

.account-avatar-fallback {
  font-size: 0.7rem;
  font-weight: 700;
  color: var(--nav-fg);
}

.account-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.account-chevron {
  font-size: 0.65rem;
  opacity: 0.7;
  flex-shrink: 0;
}

</style>
