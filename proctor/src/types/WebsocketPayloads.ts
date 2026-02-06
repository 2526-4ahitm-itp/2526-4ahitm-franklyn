
interface BaseWebsocketMessage {
  timestamp: number
}

export type WebsocketMessage = (SentinelIdMessage | AcknowledgmentMessage | Rejection
  | UpdateSentinelsMessage | FrameMessage) & BaseWebsocketMessage


export interface SentinelIdMessage {
  type: "proctor.subscribe" | "proctor.unsubscribe"
  payload: {
    sentinelId: string
  }
}

export interface AcknowledgmentMessage {
  type: "server.registration.ack",
  payload: {
    sentinelId: string
  }
}

export interface Rejection {
  type: "server.registration.reject",
  payload: {
    reason: string
  }
}

export interface UpdateSentinelsMessage {
  type: "server.update-sentinels",
  payload: {
    sentinels: string[]
  }
}

export interface FrameMessage {
  type: "server.frame",
  payload: {
    frames: Frame[]
  }
}

export interface Frame {
  sentinelId: string,
  frameId: string
  index: number
  data: string
}
