import { defineStore } from 'pinia'
import type { ProctorMessage, ServerMessage } from '@/types/WebsocketPayloads.ts'
import { ref } from 'vue'

export const useWebsocketStore = defineStore("websocketStore", () => {

  const sentinelList = ref<string[]>([
    "abc",
    "edf"
  ]);

  const protocolPrefix = import.meta.env.PROD ? "wss:" : "ws:";

  const socket = new WebSocket(`${protocolPrefix}${import.meta.env.VITE_API_URL}/ws/proctor`)

  const subscribedSentinel = ref<null | string>(null);

  const frameContent = ref<null | string>(null);

  let pageCount = 0;
  let pageAmount;
  let sentinelsToDisplayLast;
  let sentinelsToDisplayFirst;

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
      pageAmount = sentinelList.value.length / 6;
      sentinelsToDisplayLast = (pageCount + 1) * 6 - 1;
      sentinelsToDisplayFirst = pageCount * 6;
      for (const sentinel of sentinelList.value) {
        subscribeToSentinel(sentinel)
      }
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
    // if (subscribedSentinel.value !== null) {
    //    sendMessage({
    //     type: "proctor.unsubscribe",
    //     payload: {
    //       sentinelId: subscribedSentinel.value
    //     },
    //     timestamp: Date.now()
    //   })
    // }


    sendMessage({
      type: "proctor.subscribe",
      payload: {
        sentinelId: sentinelId
      },
      timestamp: Date.now()
    })

    subscribedSentinel.value = sentinelId;
  }

  function increasePageCount(){
    if (pageCount < Math.ceil(sentinelList.value.length / 6)){
      pageCount++
    }
  }

  function decreasePageCount(){
    if (pageCount > 0){
      pageCount--
    }
  }


  return {
    sentinelList,
    subscribedSentinel,
    frameContent,
  }

})
