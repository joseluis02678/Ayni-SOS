"""Citizen reports and rescuer incident endpoints."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, DbSession, require_role
from app.domain import services
from app.infrastructure.models import Report, ReportStatus, User, UserRole
from app.infrastructure.ws_hub import hub
from app.schemas import ReportCreate, ReportOut, ReportStatusUpdate

router = APIRouter(tags=["reports"])


@router.post("/reports", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def create_report(
    body: ReportCreate,
    db: DbSession,
    user: User = Depends(require_role(UserRole.citizen.value, UserRole.admin.value)),
) -> ReportOut:
    report, created = await services.create_or_get_report(db, user, body)
    out = await services.report_to_out(db, report)
    if created:
        await hub.broadcast_to_rescuers({"event": "incident.created", "data": out.model_dump(mode="json")})
    return out


@router.get("/reports/mine", response_model=list[ReportOut])
async def my_reports(
    db: DbSession,
    user: User = Depends(require_role(UserRole.citizen.value, UserRole.admin.value)),
) -> list[ReportOut]:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.citizen_id == user.id)
        .order_by(Report.created_at.desc())
    )
    return [await services.report_to_out(db, r) for r in result.scalars().all()]


@router.get("/reports/{report_id}", response_model=ReportOut)
async def get_report(report_id: UUID, db: DbSession, user: CurrentUser) -> ReportOut:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    if user.role == UserRole.citizen and report.citizen_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your report")
    return await services.report_to_out(db, report)


@router.get("/reports/{report_id}/status")
async def get_report_status(report_id: UUID, db: DbSession, user: CurrentUser) -> dict:
    out = await get_report(report_id, db, user)
    return {"id": out.id, "status": out.status, "priority": out.priority, "updated_at": out.updated_at}


@router.get("/incidents", response_model=list[ReportOut])
async def list_incidents(
    db: DbSession,
    _user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
    min_lat: float | None = None,
    max_lat: float | None = None,
    min_lon: float | None = None,
    max_lon: float | None = None,
    status_filter: ReportStatus | None = Query(None, alias="status"),
    priority_min: int | None = None,
    disaster_type: str | None = None,
) -> list[ReportOut]:
    from app.infrastructure.models import DisasterType

    dt = DisasterType(disaster_type) if disaster_type else None
    return await services.list_incidents(
        db,
        min_lat=min_lat,
        max_lat=max_lat,
        min_lon=min_lon,
        max_lon=max_lon,
        status=status_filter,
        priority_min=priority_min,
        disaster_type=dt,
    )


@router.get("/incidents/{report_id}", response_model=ReportOut)
async def get_incident(
    report_id: UUID,
    db: DbSession,
    _user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> ReportOut:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")
    return await services.report_to_out(db, report)


@router.patch("/incidents/{report_id}/status", response_model=ReportOut)
async def update_incident_status(
    report_id: UUID,
    body: ReportStatusUpdate,
    db: DbSession,
    user: User = Depends(require_role(UserRole.rescuer.value, UserRole.admin.value)),
) -> ReportOut:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")
    await services.update_report_status(db, report, body, user)
    out = await services.report_to_out(db, report)
    await hub.broadcast_to_rescuers({"event": "incident.updated", "data": out.model_dump(mode="json")})
    return out
