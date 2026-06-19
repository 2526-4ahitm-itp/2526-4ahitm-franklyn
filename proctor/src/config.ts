export interface AppConfig {
  keycloakUrl: string
  keycloakRealm: string
  keycloakClientId: string
  telemetry?: boolean
}

let config: AppConfig | undefined

export async function loadConfig(): Promise<void> {
  if (import.meta.env.DEV) {
    config = {
      keycloakUrl: import.meta.env.VITE_KCLK_URL,
      keycloakRealm: import.meta.env.VITE_KCLK_REALM,
      keycloakClientId: import.meta.env.VITE_KCLK_CLIENT_ID,
    }
    return
  }
  const res = await fetch(`${import.meta.env.BASE_URL}config.json`, { cache: 'no-store' })
  if (!res.ok) throw new Error(`failed to load runtime config: ${res.status}`)
  config = await res.json()
}

export function getConfig(): AppConfig {
  if (!config) throw new Error('config not loaded — call loadConfig() first')
  return config
}
