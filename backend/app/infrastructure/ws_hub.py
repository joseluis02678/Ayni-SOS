"""In-memory WebSocket hub for rescuer real-time updates.

For production, back this with Redis pub/sub across workers.
"""

from __future__ import annotations

import asyncio
import json
from typing import Any
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.security import decode_token

router = APIRouter(tags=["websocket"])


class ConnectionHub:
    def __init__(self) -> None:
        self._rescuers: dict[UUID, list[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect_rescuer(self, user_id: UUID, ws: WebSocket) -> None:
        await ws.accept()
        async with self._lock:
            self._rescuers.setdefault(user_id, []).append(ws)

    async def disconnect_rescuer(self, user_id: UUID, ws: WebSocket) -> None:
        async with self._lock:
            sockets = self._rescuers.get(user_id, [])
            if ws in sockets:
                sockets.remove(ws)
            if not sockets and user_id in self._rescuers:
                del self._rescuers[user_id]

    async def broadcast_to_rescuers(self, message: dict[str, Any]) -> None:
        payload = json.dumps(message, default=str)
        async with self._lock:
            targets = [ws for sockets in self._rescuers.values() for ws in sockets]
        dead: list[WebSocket] = []
        for ws in targets:
            try:
                await ws.send_text(payload)
            except Exception:  # noqa: BLE001
                dead.append(ws)
        # Cleanup dead sockets lazily
        if dead:
            async with self._lock:
                for uid, sockets in list(self._rescuers.items()):
                    self._rescuers[uid] = [s for s in sockets if s not in dead]
                    if not self._rescuers[uid]:
                        del self._rescuers[uid]


hub = ConnectionHub()


@router.websocket("/ws/rescuer")
async def rescuer_ws(websocket: WebSocket) -> None:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        return
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise ValueError("bad token type")
        if payload.get("role") not in ("rescuer", "admin"):
            raise ValueError("not a rescuer")
        user_id = UUID(payload["sub"])
    except Exception:  # noqa: BLE001
        await websocket.close(code=4401)
        return

    await hub.connect_rescuer(user_id, websocket)
    try:
        await websocket.send_text(json.dumps({"event": "connected", "data": {"user_id": str(user_id)}}))
        while True:
            # Keep-alive / client heartbeats
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text(json.dumps({"event": "pong"}))
    except WebSocketDisconnect:
        await hub.disconnect_rescuer(user_id, websocket)
