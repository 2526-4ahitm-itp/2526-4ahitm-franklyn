import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage } from '@/types/WebsocketPayloads.ts'
import { computed, reactive, ref } from 'vue'

export const useWebsocketStore = defineStore('websocketStore', () => {

  const sentinelList = ref<string[]>([])
  const currentPage = ref(0)
  const pageSize = 6
  const framesBySentinel = reactive<Record<string, string>>({})

  const socket = new WebSocket('/api/ws/proctor')

  const frameContent = reactive<string[]>([])

  let selectedSentinelList: string[] = []
  let pageCount = 1
  let sentinelsToDisplayLast: number
  let sentinelsToDisplayFirst: number

  const proctorRegister: ProctorMessage = {
    type: 'proctor.register',
    timestamp: Math.floor(Date.now() / 1000),
  }

  socket.addEventListener('open', () => {
    socket.send(JSON.stringify(proctorRegister))
  })

  socket.addEventListener('message', (event) => {
    const requestResult: ServerMessage = JSON.parse(event.data)
    if (requestResult.type === 'server.update-sentinels') {
      updateLocalSentinels(requestResult.payload.sentinels)
    } else if (requestResult.type === 'server.frame') {
      updateFrames(requestResult.payload.frames)
    }
  })

  function updateLocalSentinels(newSentinels: string[]) {
    const toAdd = newSentinels.filter(s => !sentinelList.value.includes(s))
    sentinelList.value = sentinelList.value.filter(e => newSentinels.includes(e))
    sentinelList.value.push(...toAdd)
    for (const existing of Object.keys(framesBySentinel)) {
      if (!newSentinels.includes(existing)) {
        delete framesBySentinel[existing]
      }
    }
  }

  function sendMessage(message: ProctorMessage) {
    socket.send(JSON.stringify(message))
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

  function subscribeToWanted() {
    sentinelsToDisplayLast = pageCount * 6 - 1
    sentinelsToDisplayFirst = (pageCount - 1) * 6

    for (const sentinel of sentinelList.value) {
      sendMessage({
        type: 'proctor.revoke-subscription',
        payload: {
          sentinelId: sentinel,
        },
        timestamp: Date.now(),
      })
    }

    selectedSentinelList = [];

    for (let i = 0; i < sentinelList.value.length; i++) {
      if (i >= sentinelsToDisplayFirst && i <= sentinelsToDisplayLast) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        selectedSentinelList.push(sentinelList.value[i]!)
        console.log('fuck' + selectedSentinelList.length + selectedSentinelList.toString())
        sendMessage({
          type: 'proctor.subscribe',
          payload: {
            // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
            sentinelId: sentinelList.value[i]!,
          },
          timestamp: Date.now(),
        })
      }
    }
  }

  function increasePageCount() {
    if (pageCount < Math.ceil(sentinelList.value.length / 6)) {
      pageCount++
      console.log('Hallo' + pageCount)
    }
    subscribeToWanted()
  }

  function decreasePageCount() {
    if (pageCount > 1) {
      pageCount--
      console.log('Hallo' + pageCount)
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
    decreasePageCount,
    increasePageCount,
  }
})
