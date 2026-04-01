import { createApp } from 'vue'
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'

import App from './App.vue'
import router from './router'
import { useKeycloakStore } from './stores/KeycloakStore'

const app = createApp(App)

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)
app.use(pinia)

const kc = useKeycloakStore()

await kc.init()

app.use(router)

app.mount('#app')
