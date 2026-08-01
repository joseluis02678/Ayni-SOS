"""Geolocation endpoints for rescuers."""

from fastapi import APIRouter, Depends

from app.core.deps import DbSession, require_role
from app.domain import services
from app.infrastructure.models import User, UserRole
from app.schemas import RescuerLocationUpdate

router = APIRouter(prefix="/locations", tags=["locations"])


@router.patch("/rescuer")
async def update_rescuer_location(
    body: RescuerLocationUpdate,
    db: DbSession,
    user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> dict:
    loc = await services.upsert_rescuer_location(db, user, body.latitude, body.longitude)
    return {
        "rescuer_id": str(user.id),
        "latitude": loc.latitude,
        "longitude": loc.longitude,
        "updated_at": loc.updated_at.isoformat(),
    }
