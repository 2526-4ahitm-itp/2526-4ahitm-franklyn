import { createApp } from 'vue'
import { createPinia } from 'pinia'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'
import VueKeyCloak from '@dsb-norge/vue-keycloak-js'

import App from './App.vue'
import router from './router'
import { keycloakOptions } from './keycloak'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.use(VueKeyCloak, {
  ...keycloakOptions,
  onReady: () => {
    keycloakOptions.onReady()
    app.mount('#app')
  },
})
