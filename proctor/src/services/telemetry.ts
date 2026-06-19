import * as Sentry from '@sentry/vue'
import type { App } from 'vue'
import { getConfig } from '@/config'

// TODO: put in actual DSN string
const DSN = 'changeme'

function isEnabled(): boolean {
  // Never register telemetry during local development (bun run dev).
  if (import.meta.env.DEV) return false
  // Default on, opt-out via the runtime `telemetry` config flag.
  return (getConfig().telemetry ?? false) === true
}

export function initTelemetry(app: App): void {
  if (!isEnabled()) return

  Sentry.init({
    app,
    dsn: DSN,
    release: `franklyn-proctor@${__APP_VERSION__}`,
    environment: 'production',
    // No tracesSampleRate / browserTracingIntegration → no performance traces.
  })
}

export interface TelemetryUser {
  id?: string
  username?: string
  role?: string
}

export function setTelemetryUser(user: TelemetryUser): void {
  if (!isEnabled()) return

  Sentry.setUser({
    id: user.id,
    username: user.username,
    role: user.role,
  })
}
