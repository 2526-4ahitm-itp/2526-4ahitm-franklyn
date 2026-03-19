import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import NotAllowedView from '@/views/NotAllowedView.vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import TestView from '@/views/TestView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/teachers',
      name: 'teachers',
      component: TestView,
    },
    {
      path: '/not-allowed',
      component: NotAllowedView,
      meta: { hideNav: true },
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const kc = useKeycloakStore()
  await kc.onReady()

  const isAuthenticated = kc.keycloak.authenticated === true
  const isAdmin = kc.keycloak.realmAccess?.roles.includes('franklyn-admin')
  const isTeacher = kc.keycloak.tokenParsed?.distinguished_name?.includes('OU=Teacher')

  if (!isAuthenticated) {
    return to.path === '/not-allowed' ? next() : next('/not-allowed')
  }

  if (isAdmin) {
    return next()
  }

  if (!isTeacher) {
    return to.path === '/not-allowed' ? next() : next('/not-allowed')
  }

  if (to.path === '/not-allowed') {
    return next('/')
  }

  return next()
})

export default router
