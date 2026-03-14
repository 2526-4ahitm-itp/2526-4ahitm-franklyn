<script lang="ts" setup>
import { useKeycloakStore } from '@/stores/KeycloakStore'

const kc = useKeycloakStore()

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
    <div class="navbar-center">
      <RouterLink to="/teachers" class="nav-link">Teachers</RouterLink>
    </div>
    <div class="navbar-right">
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
  background: hsl(185, 72%, 45%);
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

.navbar-center {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-left: 2.5rem;
}

.nav-link {
  color: hsla(0, 0%, 100%, 0.85);
  text-decoration: none;
  font-size: 0.95rem;
  font-weight: 500;
  transition: color 0.2s;
}

.nav-link:hover {
  color: #fff;
}

.navbar-right {
  margin-left: auto;
  flex-shrink: 0;
}

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
