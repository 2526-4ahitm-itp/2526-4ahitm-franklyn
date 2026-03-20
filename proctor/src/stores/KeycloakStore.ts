import Keycloak from 'keycloak-js'
import { defineStore } from 'pinia'

export const useKeycloakStore = defineStore('keycloakStore', () => {
  let isInit = false
  let isReady = false

  let resolveReady!: () => void
  const readyPromise = new Promise<void>((resolve) => {
    resolveReady = resolve
  })

  const keycloak = new Keycloak({
    realm: import.meta.env.VITE_KCLK_REALM,
    url: import.meta.env.VITE_KCLK_URL,
    clientId: import.meta.env.VITE_KCLK_CLIENT_ID,
  })

  async function init() {
    if (!isInit) {
      isInit = true

      let stored: StoredSession | undefined

      try {
        stored = JSON.parse(sessionStorage.stored_session ?? null) ?? undefined
      } catch (e) {
        sessionStorage.stored_session = undefined
        console.error(e)
      }

      if (stored !== undefined) {
        await keycloak.init({
          token: stored.token,
          refreshToken: stored.refreshToken,
          idToken: stored.idToken,
        })

        try {
          await keycloak.updateToken(30)
        } catch (e) {
          console.error(e)
          sessionStorage.stored_session = undefined
          await keycloak.login()
        }
      } else {
        await keycloak.init({
          onLoad: 'login-required',
        })

        stored = {
          token: keycloak.token as string,
          refreshToken: keycloak.refreshToken as string,
          idToken: keycloak.idToken as string,
        }
      }

      sessionStorage.stored_session = JSON.stringify(stored)

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

interface StoredSession {
  token: string
  refreshToken: string
  idToken: string
}
