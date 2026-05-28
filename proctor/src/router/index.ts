import { createRouter, createWebHistory } from 'vue-router'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import { useRoles } from '@/services/user'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
    },
    {
      path: '/exams',
      name: 'exams',
      component: () => import('@/views/HomeView.vue'),
    },
    {
      path: '/exams/:id',
      name: 'exam-detail',
      component: () => import('@/views/ExamDetailView.vue'),
    },
    {
      path: '/proctoring/:id?',
      name: 'proctoring',
      component: () => import('@/views/ProctoringView.vue'),
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('@/views/SettingsView.vue'),
    },
    {
      path: '/admin/notices',
      name: 'admin-notices',
      component: () => import('@/views/AdminNoticeBannersView.vue'),
    },
    {
      path: '/not-allowed',
      component: () => import('@/views/NotAllowedView.vue'),
      meta: { hideNav: true },
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const kc = useKeycloakStore()
  await kc.onReady()

  const isAuthenticated = kc.keycloak.authenticated === true
  const { isAdmin, isTeacher } = useRoles()

  const isAllowed = isAuthenticated && (isAdmin.value || isTeacher.value)

  if (!isAllowed) {
    return to.path === '/not-allowed' ? next() : next('/not-allowed')
  }

  if (to.path === '/not-allowed') {
    return next('/')
  }

  return next()
})

export default router
