import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage } from '@/types/WebsocketPayloads.ts'
import { ref } from 'vue'

export const useWebsocketStore = defineStore("websocketStore", () => {

  const sentinelList = ref<string[]>([
    "abc",
    "edf"
  ]);

  const socket = new WebSocket('ws://localhost:5050/ws/proctor')

  const subscribedSentinel = ref<null | string>(null);

  const frameContent = ref<null | string>(null);

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
      console.log(requestResult.payload.sentinels)
      sentinelList.value = requestResult.payload.sentinels;
    } else if (requestResult.type === "server.frame") {
      // get frames in payload
      if (requestResult.payload.frames[0]) {
        console.log("OK")
        frameContent.value = requestResult.payload.frames[0].data
      } else {
        console.log("NOT OK")
      }
    }
  });

  function sendMessage(message: ProctorMessage) {
    socket.send(JSON.stringify(message))
  }

  function subscribeToSentinel(sentinelId: string){
    console.log("Subscribing to sentinel", sentinelId)
     if (subscribedSentinel.value !== null) {
       sendMessage({
         type: "proctor.unsubscribe",
         payload: {
           sentinelId: subscribedSentinel.value
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

    subscribedSentinel.value = sentinelId;
  }


  return {
    sentinelList,
    subscribeToSentinel,
    subscribedSentinel,
    frameContent,
  }

})
