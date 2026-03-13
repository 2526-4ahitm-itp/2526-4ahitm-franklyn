import { createApp } from 'vue'
import { createPinia } from 'pinia'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'
import VueKeyCloak from '@dsb-norge/vue-keycloak-js'

import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(VueKeyCloak, {
  config: {
    realm: 'htlleonding',
    url: 'https://auth.htl-leonding.ac.at',
    clientId: 'htlleonding-service',
  },
  // init: {
  //   onLoad: 'login-required',
  // }
})
app.use(createPinia())
app.use(router)

app.mount('#app')
