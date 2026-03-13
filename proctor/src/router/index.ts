import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import TeacherView from '@/views/TeacherView.vue'
import { useKeycloak } from '@dsb-norge/vue-keycloak-js'
import NotAllowedView from '@/views/NotAllowedView.vue'
import { keycloakReady } from '@/keycloak'

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
      component: TeacherView,
    },
    {
      path: '/not-allowed',
      component: NotAllowedView,
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const ADMINS = ['it220266', 'it220220', 'it220231']

  if (to.path === '/not-allowed') {
    return next()
  }

  await keycloakReady

  const kc = useKeycloak()

  if (kc.ready !== true) {
    return next()
  }

  if (kc.authenticated !== true) {
    return next('/not-allowed')
  }

  // early return if admin
  if (ADMINS.includes(kc.tokenParsed?.preferred_username as string)) {
    return next()
  }

  if (!kc.tokenParsed?.ldap_entry_dn?.includes('OU=Teacher')) {
    return next('/not-allowed')
  }

  return next()
})

export default router
