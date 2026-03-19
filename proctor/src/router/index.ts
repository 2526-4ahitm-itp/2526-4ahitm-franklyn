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
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const ADMINS = ['it220266']

  if (to.path === '/not-allowed') {
    return next()
  }

  const kc = useKeycloakStore()

  await kc.onReady()

  if (kc.keycloak.authenticated !== true) {
    return next('/not-allowed')
  }

  // early return if admin
  if (ADMINS.includes(kc.keycloak.tokenParsed?.preferred_username as string)) {
    return next()
  }

  if (!kc.keycloak.tokenParsed?.distinguished_name?.includes('OU=Teacher')) {
    return next('/not-allowed')
  }

  return next()
})

export default router
