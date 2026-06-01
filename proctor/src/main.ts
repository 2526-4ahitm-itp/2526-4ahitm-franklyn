import { createApp } from 'vue'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'

import App from './App.vue'
import type { Directive } from 'vue'
import DOMPurify from 'dompurify'
import { noticeSanitizeConfig } from '@/utils/noticeMarkdown'
import router from './router'
import { useKeycloakStore } from './stores/KeycloakStore'
import { i18n } from './i18n.ts'

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

const kc = useKeycloakStore()

await kc.init()

app.use(i18n)
app.use(router)
app.directive('safe-html', safeHtmlDirective)

app.mount('#app')
