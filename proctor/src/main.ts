import { createApp } from 'vue'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
import { PiniaColada } from '@pinia/colada'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'

import App from './App.vue'
import type { Directive } from 'vue'
import DOMPurify from 'dompurify'
import { noticeSanitizeConfig } from '@/utils/noticeMarkdown'
import router from './router'
import { useKeycloakStore } from './stores/KeycloakStore'
import { i18n } from './i18n.ts'
import { installVillus } from './services/graphql'
import { initTheme } from './services/theme'
import { initTelemetry, setTelemetryUser } from './services/telemetry'
import { useRoles } from './services/user'
import { loadConfig } from './config'

// Run theme initialization before anything else to avoid flash
initTheme()

const app = createApp(App)

const safeHtmlDirective: Directive<HTMLElement, string> = {
  beforeMount(el, binding) {
    el.innerHTML = DOMPurify.sanitize(binding.value, noticeSanitizeConfig)
  },
  updated(el, binding) {
    if (binding.value === binding.oldValue) return
    el.innerHTML = DOMPurify.sanitize(binding.value, noticeSanitizeConfig)
  },
}

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)
app.use(pinia)

await loadConfig()

initTelemetry(app)

const kc = useKeycloakStore()

await kc.init()

const { isAdmin, isTeacher } = useRoles()
setTelemetryUser({
  id: kc.keycloak.subject,
  username: kc.keycloak.tokenParsed?.preferred_username,
  role: isAdmin.value ? 'admin' : isTeacher.value ? 'teacher' : 'unknown',
})

installVillus(app)
app.use(PiniaColada)
app.use(i18n)
app.use(router)
app.directive('safe-html', safeHtmlDirective)

app.mount('#app')
