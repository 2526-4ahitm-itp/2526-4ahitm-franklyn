<script setup lang="ts">
import { useKeycloakStore } from '@/stores/KeycloakStore'
import { useI18n } from 'vue-i18n'

const kc = useKeycloakStore()
const { t } = useI18n()

async function logout() {
  await kc.keycloak.logout()
}
</script>

<template>
  <div class="wrapper">
    <div class="content">
      <span class="code">403</span>
      <div class="divider"></div>
      <div class="text">
        <h1 class="title">{{ t('not_allowed.title') }}</h1>
        <span class="message">{{ t('not_allowed.info') }}</span>
        <span class="message-low"
          >{{ t('not_allowed.wrong_account') }}
          <button type="button" class="message-logout" @click="logout">{{
            t('settings.logout')
          }}</button></span
        >
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
}

.content {
  display: flex;
  align-items: center;
  gap: var(--space-10);
}

.code {
  font-family: var(--font-mono);
  font-size: 4.5rem;
  font-weight: 500;
  line-height: 1;
  color: var(--text-primary);
}

.divider {
  width: 1px;
  height: 4rem;
  background: var(--border-default);
  flex-shrink: 0;
}

.text {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.title {
  font-size: 1.4rem;
  font-weight: 600;
  margin: 0 0 0.25rem;
  color: var(--text-primary);
}

.message {
  font-size: 0.8rem;
  color: var(--text-secondary);
  line-height: 1.2;
}

.message-low {
  font-size: 0.8rem;
  line-height: 1.2;
  color: var(--text-secondary);
}

.message-logout {
  border: none;
  background: none;
  padding: 0;
  cursor: pointer;
  font: inherit;
  color: var(--text-secondary);
  text-underline-offset: 2px;
  text-decoration: underline;
  text-decoration-color: var(--border-strong);
  transition:
    color 0.1s,
    text-decoration-color 0.1s;
}

.message-logout:hover {
  color: var(--text-primary);
  text-decoration-color: var(--text-primary);
}
</style>
