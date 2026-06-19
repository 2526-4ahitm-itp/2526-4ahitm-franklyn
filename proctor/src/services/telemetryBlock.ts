import * as Sentry from '@sentry/vue'
import { isTelemetryEnabled } from '@/services/telemetry'

export type TelemetryBlockResult = 'ok' | 'blocked' | 'offline'

// Backend health endpoint (Quarkus SmallRye Health) — unauthenticated and proxied
// like the rest of /api. Used as the control probe: if this is reachable but the
// Sentry ingest host is not, the telemetry request was blocked (e.g. by an ad blocker)
// rather than the network being down.
const BACKEND_HEALTH_URL = '/api/q/health'

/**
 * Build the Sentry/Glitchtip envelope ingest URL from the configured DSN. The
 * `sentry_key` query parameter is included on purpose: ad-blocker filter lists match the
 * real envelope request by that pattern, so the probe must carry it to be blocked
 * identically. A bare URL without the query string is NOT blocked and would give a false
 * "reachable" result. Returns null when no usable DSN is configured.
 */
function ingestUrlFromDsn(): string | null {
  const dsn = Sentry.getClient()?.getDsn()
  if (!dsn?.host || !dsn.projectId || !dsn.publicKey) return null

  const protocol = dsn.protocol || 'https'
  const port = dsn.port ? `:${dsn.port}` : ''
  const path = dsn.path ? `/${dsn.path}` : ''
  const query = new URLSearchParams({
    sentry_version: '7',
    sentry_key: dsn.publicKey,
    sentry_client: 'franklyn-proctor-blockcheck',
  })
  return `${protocol}://${dsn.host}${port}${path}/api/${dsn.projectId}/envelope/?${query}`
}

/**
 * Probe the Sentry ingest endpoint, mirroring the real event request (POST + sentry_key
 * query) so ad blockers treat it the same. `no-cors` means an opaque response resolves
 * (server reached, even on 4xx/5xx) and only a transport-level failure — blocked by
 * client, DNS, offline — rejects.
 */
async function isSentryReachable(url: string): Promise<boolean> {
  try {
    await fetch(url, { method: 'POST', mode: 'no-cors', cache: 'no-store', body: '' })
    return true
  } catch {
    return false
  }
}

async function isReachable(url: string): Promise<boolean> {
  try {
    await fetch(url, { method: 'GET', mode: 'no-cors', cache: 'no-store' })
    return true
  } catch {
    return false
  }
}

/**
 * Best-effort detection of telemetry being blocked.
 *
 * - `'ok'`      — telemetry disabled, no DSN, or the ingest host is reachable.
 * - `'blocked'` — ingest host unreachable but the backend is up (server up ⇒ Sentry
 *                 should be up too, so the request was blocked, e.g. by an ad blocker).
 * - `'offline'` — both probes failed; treat as a general network problem, do not prompt.
 *
 * Note: a genuinely down Sentry server is reported as `'blocked'` by design.
 */
export async function detectTelemetryBlocked(): Promise<TelemetryBlockResult> {
  if (!isTelemetryEnabled()) return 'ok'

  const ingestUrl = ingestUrlFromDsn()
  if (!ingestUrl) return 'ok'

  if (await isSentryReachable(ingestUrl)) return 'ok'

  if (navigator.onLine === false) return 'offline'

  return (await isReachable(BACKEND_HEALTH_URL)) ? 'blocked' : 'offline'
}
