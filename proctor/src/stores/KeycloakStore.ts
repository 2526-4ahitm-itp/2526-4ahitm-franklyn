import Keycloak from 'keycloak-js'
import { defineStore } from 'pinia'
import { reactive } from 'vue'

export const useKeycloakStore = defineStore('keycloakStore', () => {
  let isInit = false
  let isReady = false

  let resolveReady!: () => void
  const readyPromise = new Promise<void>((resolve) => {
    resolveReady = resolve
  })

  const keycloak = reactive(
    new Keycloak({
      realm: import.meta.env.VITE_KCLK_REALM,
      url: import.meta.env.VITE_KCLK_URL,
      clientId: import.meta.env.VITE_KCLK_CLIENT_ID,
    }),
  )

  async function init() {
    if (!isInit) {
      isInit = true

      await keycloak.init({
        onLoad: 'login-required',
      })

      isReady = true
      resolveReady()
    }
  }

  async function onReady() {
    if (isReady) return
    await readyPromise
  }

  return {
    init,
    keycloak,
    onReady,
  }
})
