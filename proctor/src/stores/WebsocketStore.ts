import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage, SentinelInfo } from '@/types/WebsocketPayloads.ts'
import { isServerMessage } from '@/types/WebsocketPayloads.ts'
import { computed, reactive, ref, shallowRef, watch } from 'vue'
import { useKeycloakStore } from './KeycloakStore'

export const PAGE_SIZE = 6
export const MAX_RECONNECT_ATTEMPTS = 5
export const RECONNECT_DELAY_MS = 3000

export type SentinelProfile = 'HIGH' | 'MEDIUM' | 'LOW'

export const useWebsocketStore = defineStore('websocketStore', () => {
  const sentinelList = ref<SentinelInfo[]>([])
  const currentPage = ref(0)
  const framesBySentinel = reactive<Record<string, string>>({})
  const subscribedSentinels = reactive(new Set<string>())
  const socket = shallowRef<WebSocket | null>(null)
  const messageQueue: string[] = []

  const { keycloak } = useKeycloakStore()

  let reconnectTimeout: ReturnType<typeof setTimeout> | null = null
  let reconnectAttempts = 0

  function connect(): void {
    if (socket.value) return

    const token = keycloak.token
    if (token === undefined) {
      throw new Error('Keycloak token cannot be undefined')
    }

    const ws = new WebSocket('/api/ws/proctor')

    ws.addEventListener('open', () => {
      reconnectAttempts = 0
      const proctorRegister: ProctorMessage = {
        type: 'proctor.register',
        payload: {
          auth: token,
        },
        timestamp: Math.floor(Date.now() / 1000),
      }
      ws.send(JSON.stringify(proctorRegister))
      while (messageQueue.length > 0) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        ws.send(messageQueue.shift()!)
      }
    })

    ws.addEventListener('message', (event) => {
      try {
        const parsed = JSON.parse(event.data)
        if (!isServerMessage(parsed)) {
          console.error('Received malformed websocket message', parsed)
          return
        }
        const requestResult: ServerMessage = parsed
        if (requestResult.type === 'server.update-sentinels') {
          updateLocalSentinels(requestResult.payload.sentinels)
        } else if (requestResult.type === 'server.frame') {
          updateFrames(requestResult.payload.frames)
        }
      } catch (e) {
        console.error('Failed to parse websocket message', e)
      }
    })

    ws.addEventListener('close', (event) => {
      if (socket.value === ws) {
        socket.value = null
      }
      if (event.code !== 1000) {
        console.error(`WebSocket closed unexpectedly (code: ${event.code}). Attempting reconnect...`)
        handleReconnect()
      }
    })

    socket.value = ws
  }

  function handleReconnect(): void {
    if (reconnectTimeout) return
    if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      console.error('Max WebSocket reconnect attempts reached. Stopping reconnection.')
      return
    }
    reconnectTimeout = setTimeout(() => {
      reconnectTimeout = null
      reconnectAttempts++
      try {
        connect()
      } catch (e) {
        console.error('Reconnect failed, retrying...', e)
        handleReconnect()
      }
    }, RECONNECT_DELAY_MS)
  }

  async function disconnect(): Promise<void> {
    if (reconnectTimeout) {
      clearTimeout(reconnectTimeout)
      reconnectTimeout = null
    }
    reconnectAttempts = 0

    const ws = socket.value
    if (ws) {
      socket.value = null
      if (ws.readyState !== WebSocket.CLOSED && ws.readyState !== WebSocket.CLOSING) {
        await new Promise<void>((resolve) => {
          ws.addEventListener('close', () => resolve(), { once: true })
          ws.close()
        })
      }
    }
    sentinelList.value = []
    for (const key of Object.keys(framesBySentinel)) {
      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete framesBySentinel[key]
    }
    subscribedSentinels.clear()
    messageQueue.length = 0
  }

  function prevPage(): void {
    if (currentPage.value > 0) {
      currentPage.value--
    }
  }

  function nextPage(): void {
    if (currentPage.value < totalPages.value - 1) {
      currentPage.value++
    }
  }

  function updateLocalSentinels(newSentinels: SentinelInfo[]): void {
    const newIds = new Set(newSentinels.map((s) => s.sentinelId))
    const existingIds = new Set(sentinelList.value.map((s) => s.sentinelId))
    const toAdd = newSentinels.filter((s) => !existingIds.has(s.sentinelId))
    sentinelList.value = sentinelList.value.filter((e) => newIds.has(e.sentinelId))
    sentinelList.value.push(...toAdd)
    for (const existing of Object.keys(framesBySentinel)) {
      if (!newIds.has(existing)) {
        // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
        delete framesBySentinel[existing]
      }
    }
  }

  function sendMessage(message: ProctorMessage): void {
    if (!socket.value) return

    if (socket.value.readyState === WebSocket.OPEN) {
      socket.value.send(JSON.stringify(message))
    } else if (socket.value.readyState === WebSocket.CONNECTING) {
      messageQueue.push(JSON.stringify(message))
    }
  }

  function subscribeToSentinel(sentinelId: string): void {
    if (subscribedSentinels.has(sentinelId)) {
      return
    }
    subscribedSentinels.add(sentinelId)
    sendMessage({
      type: 'proctor.subscribe',
      payload: { sentinelId },
      timestamp: Math.floor(Date.now() / 1000),
    })
    setProfile(sentinelId, 'LOW')
  }

  function revokeSubscription(sentinelId: string): void {
    if (!subscribedSentinels.has(sentinelId)) {
      return
    }
    subscribedSentinels.delete(sentinelId)
    sendMessage({
      type: 'proctor.revoke-subscription',
      payload: { sentinelId },
      timestamp: Math.floor(Date.now() / 1000),
    })
  }

  function setProfile(sentinelId: string, profile: SentinelProfile): void {
    sendMessage({
      type: 'proctor.set-profile',
      payload: { sentinelId, profile },
      timestamp: Math.floor(Date.now() / 1000),
    })
  }

  function setPin(pin: number): void {
    sendMessage({
      type: 'proctor.set-pin',
      payload: { pin },
      timestamp: Math.floor(Date.now() / 1000),
    })
  }

  function updateFrames(frames: { sentinelId: string; data: string }[]): void {
    for (const frame of frames) {
      framesBySentinel[frame.sentinelId] = frame.data
    }
  }

  const totalPages = computed<number>(() => {
    return Math.max(1, Math.ceil(sentinelList.value.length / PAGE_SIZE))
  })

  const pagedSentinels = computed<SentinelInfo[]>(() => {
    const start = currentPage.value * PAGE_SIZE
    return sentinelList.value.slice(start, start + PAGE_SIZE)
  })

  watch(totalPages, (nextTotal) => {
    if (currentPage.value > nextTotal - 1) {
      currentPage.value = Math.max(0, nextTotal - 1)
    }
  })

  watch(
    pagedSentinels,
    (nextSentinels, prevSentinels = []) => {
      const nextIds = new Set(nextSentinels.map((s) => s.sentinelId))
      for (const sentinel of nextSentinels) {
        subscribeToSentinel(sentinel.sentinelId)
      }
      for (const sentinel of prevSentinels) {
        if (!nextIds.has(sentinel.sentinelId)) {
          revokeSubscription(sentinel.sentinelId)
        }
      }
    },
    { immediate: true },
  )

  return {
    currentPage,
    totalPages,
    pagedSentinels,
    pageSize: PAGE_SIZE,
    framesBySentinel,
    setProfile,
    setPin,
    connect,
    disconnect,
    prevPage,
    nextPage,
  }
})
