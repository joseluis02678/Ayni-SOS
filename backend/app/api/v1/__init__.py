"""API v1 router aggregation."""

from fastapi import APIRouter

from app.api.v1 import assignments, auth, locations, reports, sync
from app.infrastructure.ws_hub import router as ws_router

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(reports.router)
api_router.include_router(assignments.router)
api_router.include_router(sync.router)
api_router.include_router(locations.router)
api_router.include_router(ws_router)
