let resolveKeycloak!: () => void // the ! tells TS it will be assigned before use

export const keycloakReady = new Promise<void>((resolve) => {
  resolveKeycloak = resolve
})

export const keycloakOptions = {
  config: {
    realm: import.meta.env.VITE_KCLK_REALM,
    url: import.meta.env.VITE_KCLK_URL,
    clientId: import.meta.env.VITE_KCLK_CLIENT_ID,
  },
  init: {
    onLoad: 'login-required',
  },
  onReady: (): void => {
    resolveKeycloak()
  },
}
