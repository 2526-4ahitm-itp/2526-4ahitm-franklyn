import { createApp } from 'vue'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
import { PiniaColada } from '@pinia/colada'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'

import App from './App.vue'
import router from './router'
import { useKeycloakStore } from './stores/KeycloakStore'
import { i18n } from './i18n.ts'
import { installVillus } from './services/graphql'

const app = createApp(App)

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)
app.use(pinia)

const kc = useKeycloakStore()

await kc.init()

installVillus(app)
app.use(PiniaColada)
app.use(i18n)
app.use(router)

app.mount('#app')
