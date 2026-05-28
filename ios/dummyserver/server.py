"""
Franklyn Dummy Chat Server

Run:
    nix develop .#dummyserver -c fr-dummyserver
        or from the dummyserver shell:
    uvicorn server:app --reload --port 8000

HTTP endpoint (matches existing iOS call):
    POST /api/chat/message  { examId, message }

WebSocket:
    WS /api/ws/chat
    After connect, send { "type": "chat.join", "payload": { "examId": "<id>" }, "timestamp": 0 }

Debug:
    GET /api/chat/rooms
    GET /api/chat/rooms/{examId}/messages
"""

from __future__ import annotations

import time
import uuid
from collections import defaultdict
from typing import Any

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Franklyn Dummy Chat Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# In-memory state
# ---------------------------------------------------------------------------

rooms: dict[str, list[dict]] = defaultdict(list)
room_connections: dict[str, set[WebSocket]] = defaultdict(set)

# ---------------------------------------------------------------------------
# Envelope helpers — { type, timestamp, payload } matches WsMessage format
# ---------------------------------------------------------------------------


def envelope(msg_type: str, payload: Any) -> dict:
    return {"type": msg_type, "timestamp": int(time.time()), "payload": payload}


async def broadcast(room_id: str, msg_type: str, payload: Any, exclude: WebSocket | None = None) -> None:
    frame = envelope(msg_type, payload)
    dead: list[WebSocket] = []
    for ws in list(room_connections[room_id]):
        if ws is exclude:
            continue
        try:
            await ws.send_json(frame)
        except Exception:
            dead.append(ws)
    for ws in dead:
        room_connections[room_id].discard(ws)


async def send_to(ws: WebSocket, msg_type: str, payload: Any) -> None:
    await ws.send_json(envelope(msg_type, payload))


# ---------------------------------------------------------------------------
# HTTP — POST /api/chat/message
# ---------------------------------------------------------------------------


class PostMessageRequest(BaseModel):
    examId: str
    message: str


@app.post("/api/chat/message")
async def post_message(body: PostMessageRequest):
    msg = {
        "id": str(uuid.uuid4()),
        "examId": body.examId,
        "text": body.message,
        "sender": "teacher",
        "timestamp": int(time.time()),
        "read": False,
    }
    rooms[body.examId].append(msg)
    await broadcast(body.examId, "chat.message", msg)
    return {"ok": True, "message": msg}


# ---------------------------------------------------------------------------
# WebSocket — WS /api/ws/chat
#
# Client → Server:
#   chat.join  { examId }          subscribe to a room, replays history
#   chat.read  { examId? }         mark all messages read, broadcast receipt
#
# Server → Client:
#   chat.history      { messages }
#   chat.message      { id, examId, text, sender, timestamp, read }
#   chat.read_receipt { examId, readAt }
#   chat.error        { reason }
# ---------------------------------------------------------------------------


@app.websocket("/api/ws/chat")
async def websocket_chat(ws: WebSocket):
    await ws.accept()
    current_room: str | None = None

    try:
        while True:
            data = await ws.receive_json()
            msg_type: str = data.get("type", "")
            payload: dict = data.get("payload", {})

            if msg_type == "chat.join":
                room_id = payload.get("examId")
                if not room_id:
                    await send_to(ws, "chat.error", {"reason": "examId is required"})
                    continue
                if current_room and current_room != room_id:
                    room_connections[current_room].discard(ws)
                current_room = room_id
                room_connections[room_id].add(ws)
                await send_to(ws, "chat.history", {"messages": rooms[room_id]})

            elif msg_type == "chat.read":
                room_id = payload.get("examId") or current_room
                if not room_id:
                    await send_to(ws, "chat.error", {"reason": "not in a room"})
                    continue
                for msg in rooms[room_id]:
                    msg["read"] = True
                await broadcast(room_id, "chat.read_receipt", {"examId": room_id, "readAt": int(time.time())}, exclude=ws)

            else:
                await send_to(ws, "chat.error", {"reason": f"unknown type: {msg_type!r}"})

    except WebSocketDisconnect:
        pass
    except Exception as exc:
        try:
            await send_to(ws, "chat.error", {"reason": str(exc)})
        except Exception:
            pass
    finally:
        if current_room:
            room_connections[current_room].discard(ws)


# ---------------------------------------------------------------------------
# Debug endpoints
# ---------------------------------------------------------------------------


@app.get("/api/chat/rooms")
async def list_rooms():
    return {
        room_id: {
            "messageCount": len(msgs),
            "activeConnections": len(room_connections[room_id]),
        }
        for room_id, msgs in rooms.items()
    }


@app.get("/api/chat/rooms/{exam_id}/messages")
async def get_room_messages(exam_id: str):
    return {"examId": exam_id, "messages": rooms[exam_id]}


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
