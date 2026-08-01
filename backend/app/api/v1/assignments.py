"""Assignment endpoints for collaborative rescue."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.deps import require_role
from app.core.deps import DbSession
from app.domain import services
from app.infrastructure.models import Assignment, Report, User, UserRole
from app.infrastructure.ws_hub import hub
from app.schemas import AssignmentOut, AssignmentStatusUpdate

router = APIRouter(tags=["assignments"])


@router.post("/incidents/{report_id}/accept", response_model=AssignmentOut, status_code=status.HTTP_201_CREATED)
async def accept_incident(
    report_id: UUID,
    db: DbSession,
    user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> AssignmentOut:
    result = await db.execute(select(Report).where(Report.id == report_id))
    report = result.scalar_one_or_none()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    assignment = await services.accept_assignment(db, report, user)
    out = services.assignment_to_out(assignment, rescuer_name=user.full_name)
    await hub.broadcast_to_rescuers(
        {"event": "assignment.changed", "data": out.model_dump(mode="json")}
    )
    return out


@router.get("/incidents/{report_id}/assignees", response_model=list[AssignmentOut])
async def list_assignees(
    report_id: UUID,
    db: DbSession,
    _user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> list[AssignmentOut]:
    result = await db.execute(
        select(Assignment)
        .options(selectinload(Assignment.rescuer))
        .where(Assignment.report_id == report_id)
    )
    return [services.assignment_to_out(a) for a in result.scalars().all()]


@router.patch("/assignments/{assignment_id}", response_model=AssignmentOut)
async def update_assignment(
    assignment_id: UUID,
    body: AssignmentStatusUpdate,
    db: DbSession,
    user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> AssignmentOut:
    result = await db.execute(
        select(Assignment)
        .options(selectinload(Assignment.rescuer))
        .where(Assignment.id == assignment_id)
    )
    assignment = result.scalar_one_or_none()
    if assignment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")
    if assignment.rescuer_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your assignment")

    assignment.status = body.status
    await db.flush()
    out = services.assignment_to_out(assignment)
    await hub.broadcast_to_rescuers(
        {"event": "assignment.changed", "data": out.model_dump(mode="json")}
    )
    return out


@router.get("/assignments/mine", response_model=list[AssignmentOut])
async def my_assignments(
    db: DbSession,
    user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> list[AssignmentOut]:
    result = await db.execute(
        select(Assignment)
        .options(selectinload(Assignment.rescuer))
        .where(Assignment.rescuer_id == user.id)
        .order_by(Assignment.accepted_at.desc())
    )
    return [services.assignment_to_out(a) for a in result.scalars().all()]
