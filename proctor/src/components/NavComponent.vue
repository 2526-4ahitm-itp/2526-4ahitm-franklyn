<script lang="ts" setup>
import { computed } from 'vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'

const kc = useKeycloakStore()
const isAdmin = computed(() => kc.keycloak.realmAccess?.roles.includes('franklyn-admin'))

async function logout() {
  await kc.keycloak.logout()
}
</script>

<template>
  <nav class="navbar">
    <div class="navbar-left">
      <RouterLink to="/" class="logo">
        <img class="logo-img" src="@/assets/img/logo.png" alt="Logo" />
        <span class="logo-text">FRANKLYN</span>
      </RouterLink>
    </div>
    <div class="navbar-right">
      <RouterLink
        v-if="isAdmin"
        to="/admin/notices"
        class="nav-button btn-admin"
        aria-label="Open admin notice banners"
      >
        Admin
      </RouterLink>
      <button class="nav-button btn-logout" @click="logout">Logout</button>
    </div>
  </nav>
</template>

<style scoped>
.navbar {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0.75rem 1.5rem;
  background: var(--primary);
  box-sizing: border-box;
}

.navbar-left {
  flex-shrink: 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  text-decoration: none;
}

.logo-img {
  width: 36px;
  height: 36px;
  border-radius: 6px;
  object-fit: contain;
}

.logo-text {
  font-weight: 700;
  font-size: 1.1rem;
  color: #fff;
  letter-spacing: 0.05em;
}

.navbar-right {
  margin-left: auto;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 1rem;
}
.nav-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.45rem 1.1rem;
  border: 1.5px solid hsla(0, 0%, 100%, 0.65);
  border-radius: 6px;
  background: transparent;
  color: #fff;
  font-size: 0.9rem;
  font-weight: 600;
  line-height: 1;
  text-decoration: none;
  cursor: pointer;
  transition:
    background 0.2s,
    border-color 0.2s,
    transform 0.2s;
}

.nav-button:hover {
  background: hsla(0, 0%, 100%, 0.16);
  border-color: #fff;
}

.nav-button:active {
  transform: translateY(1px);
}

.nav-button:focus-visible {
  outline: 2px solid hsla(0, 0%, 100%, 0.75);
  outline-offset: 2px;
}
</style>
