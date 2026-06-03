import { useKeycloakStore } from '@/stores/KeycloakStore'

export async function downloadSentinelVideo(sentinelId: string, filename: string): Promise<void> {
  const { keycloak } = useKeycloakStore()
  try {
    await keycloak.updateToken(30)
  } catch {
    await keycloak.login()
    return
  }
  const res = await fetch(`/api/videos/${sentinelId}.mp4`, {
    headers: { Authorization: `Bearer ${keycloak.token}` },
  })
  if (!res.ok) throw new Error(`Download failed: ${res.status}`)
  const blob = await res.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}
