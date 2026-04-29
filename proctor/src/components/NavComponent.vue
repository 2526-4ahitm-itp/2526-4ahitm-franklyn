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
        class="btn-admin"
        aria-label="Open admin notice banners"
      >
        Admin
      </RouterLink>
      <button class="btn-logout" @click="logout">Logout</button>
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

<<<<<<< HEAD
=======
.btn-admin {
  padding: 0.45rem 1.1rem;
  border: 1.5px solid hsla(0, 0%, 100%, 0.7);
  border-radius: 5px;
  background: transparent;
  color: #fff;
  font-size: 0.9rem;
  font-weight: 500;
  text-decoration: none;
  transition:
    background 0.2s,
    border-color 0.2s;
}

.btn-admin:hover {
  background: hsla(0, 0%, 100%, 0.15);
  border-color: #fff;
}

.btn-settings {
  width: 2.25rem;
  height: 2.25rem;
  border: 1.5px solid hsla(0, 0%, 100%, 0.7);
  border-radius: 5px;
  background: transparent;
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  font-size: 1rem;
  transition:
    background 0.2s,
    border-color 0.2s;
}

.btn-settings:hover {
  background: hsla(0, 0%, 100%, 0.15);
  border-color: #fff;
}

>>>>>>> d733152 (feat(proctor): add admin panel with notice banners CRUD)
.btn-logout {
  padding: 0.45rem 1.1rem;
  border: 1.5px solid hsla(0, 0%, 100%, 0.7);
  border-radius: 5px;
  background: transparent;
  color: #fff;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition:
    background 0.2s,
    border-color 0.2s;
}

.btn-logout:hover {
  background: hsla(0, 0%, 100%, 0.15);
  border-color: #fff;
}
</style>
