interface BaseWebsocketMessage {
  timestamp: number
}

export type ProctorMessage = (
  | SentinelIdMessage
  | RegisterMessage
  | SetProfileMessage
  | SubscribePinMessage
) &
  BaseWebsocketMessage

export type ServerMessage = (
  | AcknowledgmentMessage
  | Rejection
  | UpdateSentinelsMessage
  | FrameMessage
) &
  BaseWebsocketMessage

export interface RegisterMessage {
  type: 'proctor.register'
  payload: {
    auth: string
  }
}

export interface SentinelIdMessage {
  type: 'proctor.subscribe' | 'proctor.revoke-subscription'
  payload: {
    sentinelId: string
  }
}

export interface SetProfileMessage {
  type: 'proctor.set-profile'
  payload: {
    sentinelId: string
    profile: 'HIGH' | 'MEDIUM' | 'LOW'
  }
}

export interface SubscribePinMessage {
  type: 'proctor.set-pin'
  payload: {
    pin: number
  }
}

export interface AcknowledgmentMessage {
  type: 'server.registration.ack'
  payload: {
    proctorId: string
  }
}

export interface Rejection {
  type: 'server.registration.reject'
  payload: {
    reason: string
  }
}

export interface SentinelInfo {
  sentinelId: string
  name: string
}

export interface UpdateSentinelsMessage {
  type: 'server.update-sentinels'
  payload: {
    sentinels: SentinelInfo[]
  }
}

export interface FrameMessage {
  type: 'server.frame'
  payload: {
    frames: Frame[]
  }
}

export interface Frame {
  sentinelId: string
  frameId: string
  index: number
  data: string
}

export function isServerMessage(data: unknown): data is ServerMessage {
  if (typeof data !== 'object' || data === null) return false

  const msg = data as Record<string, unknown>
  if (
    typeof msg.type !== 'string' ||
    typeof msg.timestamp !== 'number' ||
    typeof msg.payload !== 'object' ||
    msg.payload === null
  ) {
    return false
  }

  const payload = msg.payload as Record<string, unknown>

  switch (msg.type) {
    case 'server.registration.ack':
      return typeof payload.proctorId === 'string'
    case 'server.registration.reject':
      return typeof payload.reason === 'string'
    case 'server.update-sentinels':
      if (!Array.isArray(payload.sentinels)) return false
      return payload.sentinels.every(
        (s) =>
          typeof s === 'object' &&
          s !== null &&
          typeof (s as Record<string, unknown>).sentinelId === 'string' &&
          typeof (s as Record<string, unknown>).name === 'string',
      )
    case 'server.frame':
      if (!Array.isArray(payload.frames)) return false
      return payload.frames.every(
        (f) =>
          typeof f === 'object' &&
          f !== null &&
          typeof (f as Record<string, unknown>).sentinelId === 'string' &&
          typeof (f as Record<string, unknown>).frameId === 'string' &&
          typeof (f as Record<string, unknown>).index === 'number' &&
          typeof (f as Record<string, unknown>).data === 'string',
      )
    default:
      return false
  }
}
