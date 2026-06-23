import * as Sentry from '@sentry/vue'
import type { App } from 'vue'
import { getConfig } from '@/config'

const DSN = 'https://e5c730457a1a476ba98daf19be4cae18@franklyn.htl-leonding.ac.at/glitchtip/2'

export function isTelemetryEnabled(): boolean {
  // Never register telemetry during local development (bun run dev).
  if (import.meta.env.DEV) return false
  // Default off, opt-in via the runtime `telemetry` config flag.
  return (getConfig().telemetry ?? false) === true
}

export function initTelemetry(app: App): void {
  if (!isTelemetryEnabled()) return

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
  if (!isTelemetryEnabled()) return

  Sentry.setUser({
    id: user.id,
    username: user.username,
    role: user.role,
  })
}
