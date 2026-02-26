import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage } from '@/types/WebsocketPayloads.ts'
import { ref } from 'vue'

export const useWebsocketStore = defineStore('websocketStore', () => {
  const sentinelList = ref<string[]>(['abc', 'edf'])

  const protocolPrefix = import.meta.env.PROD ? 'wss:' : 'ws:'

  const socket = new WebSocket(`${protocolPrefix}${import.meta.env.VITE_API_URL}/ws/proctor`)

  const frameContent = ref<null | string>(null)

  let selectedSentinelList: string[] = []
  let pageCount = 1
  let sentinelsToDisplayLast: number
  let sentinelsToDisplayFirst: number

  const proctorRegister: ProctorMessage = {
    type: 'proctor.register',
    timestamp: Date.now(),
  }

  socket.addEventListener('open', () => {
    socket.send(JSON.stringify(proctorRegister))
  })

  socket.addEventListener('message', (event) => {
    const requestResult: ServerMessage = JSON.parse(event.data)
    if (requestResult.type === 'server.update-sentinels') {
      sentinelList.value = requestResult.payload.sentinels
      subscribeToWanted()
    } else if (requestResult.type === 'server.frame') {
      // get frames in payload
      if (requestResult.payload.frames[0]) {
        console.log('OK')
        frameContent.value = requestResult.payload.frames[0].data
      } else {
        console.log('NOT OK')
      }
    }
  })

  function sendMessage(message: ProctorMessage) {
    socket.send(JSON.stringify(message))
  }

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
    pageCount,
    decreasePageCount,
    increasePageCount,
  }
})
