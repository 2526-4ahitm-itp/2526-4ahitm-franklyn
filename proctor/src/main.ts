import {createApp, h, provide} from 'vue'
import { createPinia } from 'pinia'
import {DefaultApolloClient} from '@vue/apollo-composable'

import 'bootstrap-icons/font/bootstrap-icons.min.css'
import '@/assets/main.css'

import App from './App.vue'
import router from './router'
import {apolloClient} from "@/stores/ApolloClient.ts";

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient)
  },

  render: () => h(App),
})

app.use(createPinia())
app.use(router)

app.mount('#app')
