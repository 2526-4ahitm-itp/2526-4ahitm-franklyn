
interface BaseWebsocketMessage {
  timestamp: number
}

export type ProctorMessage = (SentinelIdMessage | RegisterMessage | SetProfileMessage | SubscribePinMessage) & BaseWebsocketMessage

export type ServerMessage = (AcknowledgmentMessage | Rejection | UpdateSentinelsMessage |
  FrameMessage) & BaseWebsocketMessage

export interface RegisterMessage {
  type: "proctor.register"
  payload: {
    auth: string
  }
}

export interface SentinelIdMessage {
  type: "proctor.subscribe" | "proctor.revoke-subscription"
  payload: {
    sentinelId: string
  }
}

export interface SetProfileMessage {
  type: "proctor.set-profile"
  payload: {
    sentinelId: string
    profile: "HIGH" | "MEDIUM" | "LOW"
  }
}

export interface SubscribePinMessage {
  type: "proctor.set-pin"
  payload: {
    pin: number
  }
}

export interface AcknowledgmentMessage {
  type: "server.registration.ack",
  payload: {
    proctorId: string
  }
}

export interface Rejection {
  type: "server.registration.reject",
  payload: {
    reason: string
  }
}

export interface SentinelInfo {
  sentinelId: string
  name: string
}

export interface UpdateSentinelsMessage {
  type: "server.update-sentinels",
  payload: {
    sentinels: SentinelInfo[]
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
