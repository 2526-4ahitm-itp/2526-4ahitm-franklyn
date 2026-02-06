import { defineStore } from 'pinia'
import type { WebsocketMessage } from '@/types/WebsocketPayloads.ts'
import { ref } from 'vue'

export const useWebsocketStore = defineStore("websocketStore", () => {

  const sentinelList = ref<string[]>([]);
  let subscribedSentinel: null | string = null;

  const socket = new WebSocket("ws://localhost:8080")

  const proctorRegister: ProctorMessage = {
    type: "proctor.register",
    timestamp: Date.now()
  }

  socket.addEventListener("open", () => {
    socket.send(JSON.stringify(proctorRegister))
  })

  socket.addEventListener("message", (event) => {
    const requestResult: ServerMessage = JSON.parse(event.data)
    if (requestResult.type === "server.update-sentinels") {
      // update sentinelList
    } else if (requestResult.type === "server.frame") {
      // get frames in payload
    }
  });

  function sendMessage(message: WebsocketMessage) {
    socket.send(JSON.stringify(message))
  }

  function subscribeToSentinel(sentinelId: string){
     if (subscribedSentinel !== null) {
       sendMessage({
         type: "proctor.unsubscribe",
         payload: {
           sentinelId: subscribedSentinel
         },
         timestamp: Date.now()
       })
     }

    sendMessage({
      type: "proctor.subscribe",
      payload: {
        sentinelId: sentinelId
      },
      timestamp: Date.now()
    })

    subscribedSentinel = sentinelId;
  }


  return {
    sentinelList,
    subscribeToSentinel
  }

})
