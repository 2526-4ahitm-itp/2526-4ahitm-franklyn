import { createRouter, createWebHistory } from 'vue-router'
import NotAllowedView from '@/views/NotAllowedView.vue'
import { useKeycloakStore } from '@/stores/KeycloakStore'
import ExamView from '@/views/HomeView.vue'
import ProctoringView from '@/views/ProctoringView.vue'
import HomeView from '@/views/HomeView.vue'
import ExamDetailView from '@/views/ExamDetailView.vue'
import SettingsView from '@/views/SettingsView.vue'
import AdminNoticeBannersView from '@/views/AdminNoticeBannersView.vue'
// import {loadLocaleMessages, setI18nLanguage, setupI18n, SUPPORT_LOCALES} from "@/i18n.ts";
//
// const i18n = setupI18n({locale: 'en'})
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/exams',
      name: 'exams',
      component: ExamView,
    },
    {
      path: '/exams/:id',
      name: 'exam-detail',
      component: ExamDetailView,
    },
    {
      path: '/proctoring/:id',
      name: 'proctoring',
      component: ProctoringView,
    },
    {
      path: '/proctoring',
      name: 'proctoring-select',
      component: ProctoringView,
    },
    {
      path: '/settings',
      name: 'settings',
      component: SettingsView
    },
    {
      path: '/admin/notices',
      name: 'admin-notices',
      component: AdminNoticeBannersView,
    },
    {
      path: '/not-allowed',
      component: NotAllowedView,
      meta: { hideNav: true },
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  // const paramsLocale = to.params.locale
  const kc = useKeycloakStore()
  await kc.onReady()

  const isAuthenticated = kc.keycloak.authenticated === true
  const isAdmin = kc.keycloak.realmAccess?.roles.includes('franklyn-admin')
  const isTeacher = kc.keycloak.tokenParsed?.distinguished_name?.includes('OU=Teacher')

  // if (!SUPPORT_LOCALES.includes(<string>paramsLocale)) {
  //   return next(`/${i18n.global.locale}`)
  // }
  // if (!i18n.global.availableLocales.includes(<string> paramsLocale)) {
  //   if (typeof paramsLocale === "string") {
  //     await loadLocaleMessages(i18n, paramsLocale)
  //   }
  // }
  if (!isAuthenticated) {
    return to.path === '/not-allowed' ? next() : next('/not-allowed')
  }

  // if(typeof  paramsLocale === "string" ){
  //   setI18nLanguage(i18n, paramsLocale)
  // }

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
