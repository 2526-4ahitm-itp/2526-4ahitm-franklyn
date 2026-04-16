import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage, SentinelInfo } from '@/types/WebsocketPayloads.ts'
import { computed, reactive, ref, shallowRef, watch } from 'vue'
import { useKeycloakStore } from './KeycloakStore'

export const useWebsocketStore = defineStore('websocketStore', () => {
  const sentinelList = ref<SentinelInfo[]>([])
  const currentPage = ref(0)
  const pageSize = 6
  const framesBySentinel = reactive<Record<string, string>>({})
  const subscribedSentinels = reactive(new Set<string>())
  const socket = shallowRef<WebSocket | null>(null)
  const messageQueue: string[] = []

  const { keycloak } = useKeycloakStore()

  const frameContent = reactive<string[]>([])

  let selectedSentinelList: string[] = []
  let pageCount = 1
  let sentinelsToDisplayLast: number
  let sentinelsToDisplayFirst: number

  function connect() {
    if (socket.value) return

    const token = keycloak.token

    if (token === undefined) {
      throw new Error('Keycloak token cannot be undefined')
    }

    const ws = new WebSocket('/api/ws/proctor')

    ws.addEventListener('open', () => {
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
      const requestResult: ServerMessage = JSON.parse(event.data)
      if (requestResult.type === 'server.update-sentinels') {
        updateLocalSentinels(requestResult.payload.sentinels)
      } else if (requestResult.type === 'server.frame') {
        updateFrames(requestResult.payload.frames)
      }
    })

    socket.value = ws
  }

  function disconnect() {
    if (socket.value) {
      socket.value.close()
      socket.value = null
    }
    sentinelList.value = []
    for (const key of Object.keys(framesBySentinel)) {
        // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
        delete framesBySentinel[key]
    }
    subscribedSentinels.clear()
    messageQueue.length = 0
  }

  function updateLocalSentinels(newSentinels: SentinelInfo[]) {
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

  function sendMessage(message: ProctorMessage) {
    if (!socket.value) return

    if (socket.value.readyState === WebSocket.OPEN) {
      socket.value.send(JSON.stringify(message))
    } else if (socket.value.readyState === WebSocket.CONNECTING) {
      messageQueue.push(JSON.stringify(message))
    }
  }

  function subscribeToSentinel(sentinelId: string) {
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

  function revokeSubscription(sentinelId: string) {
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

  function setProfile(sentinelId: string, profile: 'HIGH' | 'MEDIUM' | 'LOW') {
    sendMessage({
      type: 'proctor.set-profile',
      payload: { sentinelId, profile },
      timestamp: Math.floor(Date.now() / 1000),
    })
  }

  function setPin(pin: number) {
    sendMessage({
      type: 'proctor.set-pin',
      payload: { pin },
      timestamp: Math.floor(Date.now() / 1000),
    })
  }

  function updateFrames(frames: { sentinelId: string; data: string }[]) {
    for (const frame of frames) {
      framesBySentinel[frame.sentinelId] = frame.data
    }
  }

  const totalPages = computed(() => {
    return Math.max(1, Math.ceil(sentinelList.value.length / pageSize))
  })

  const pagedSentinels = computed(() => {
    const start = currentPage.value * pageSize
    return sentinelList.value.slice(start, start + pageSize)
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

  function subscribeToWanted() {
    sentinelsToDisplayLast = pageCount * 6 - 1
    sentinelsToDisplayFirst = (pageCount - 1) * 6

    for (const sentinel of sentinelList.value) {
      sendMessage({
        type: 'proctor.revoke-subscription',
        payload: {
          sentinelId: sentinel.sentinelId,
        },
        timestamp: Date.now(),
      })
    }

    selectedSentinelList = []

    for (let i = 0; i < sentinelList.value.length; i++) {
      if (i >= sentinelsToDisplayFirst && i <= sentinelsToDisplayLast) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        selectedSentinelList.push(sentinelList.value[i]!.sentinelId)
        sendMessage({
          type: 'proctor.subscribe',
          payload: {
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            sentinelId: sentinelList.value[i]!.sentinelId,
          },
          timestamp: Date.now(),
        })
      }
    }
  }

  function increasePageCount() {
    if (pageCount < Math.ceil(sentinelList.value.length / 6)) {
      pageCount++
    }
    subscribeToWanted()
  }

  function decreasePageCount() {
    if (pageCount > 1) {
      pageCount--
    }
    subscribeToWanted()
  }

  return {
    selectedSentinelList,
    frameContent,
    currentPage,
    totalPages,
    pagedSentinels,
    pageSize,
    framesBySentinel,
    pageCount,
    setProfile,
    decreasePageCount,
    increasePageCount,
    setPin,
    connect,
    disconnect,
  }
})
