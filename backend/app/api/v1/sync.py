"""Sync endpoints: push batch, pull cursor, SMS inbound, media upload."""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.core.deps import CurrentUser, DbSession, require_role
from app.domain import services
from app.infrastructure.media import ensure_bucket, put_object
from app.infrastructure.models import EvidenceMedia, Report, User, UserRole
from app.infrastructure.ws_hub import hub
from app.schemas import (
    ReportCreate,
    ReportOut,
    SmsInboundRequest,
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
)

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(body: SyncPushRequest, db: DbSession, user: CurrentUser) -> SyncPushResponse:
    accepted: list[UUID] = []
    rejected: list[dict] = []

    for item in body.items:
        try:
            if item.operation == "create_report":
                data = ReportCreate.model_validate(item.payload)
                report, created = await services.create_or_get_report(db, user, data)
                accepted.append(item.client_id)
                if created:
                    out = await services.report_to_out(db, report)
                    await hub.broadcast_to_rescuers(
                        {"event": "incident.created", "data": out.model_dump(mode="json")}
                    )
            else:
                rejected.append({"client_id": str(item.client_id), "reason": f"Unknown op {item.operation}"})
        except Exception as exc:  # noqa: BLE001 — batch sync must not fail entirely
            rejected.append({"client_id": str(item.client_id), "reason": str(exc)})

    return SyncPushResponse(accepted=accepted, rejected=rejected)


@router.get("/pull", response_model=SyncPullResponse)
async def sync_pull(
    db: DbSession,
    user: CurrentUser,
    since: datetime | None = None,
) -> SyncPullResponse:
    cursor = since or datetime(1970, 1, 1, tzinfo=UTC)
    now = datetime.now(UTC)

    if user.role == UserRole.citizen:
        result = await db.execute(
            select(Report)
            .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
            .where(Report.citizen_id == user.id, Report.updated_at > cursor)
            .order_by(Report.updated_at.asc())
        )
        reports = [await services.report_to_out(db, r) for r in result.scalars().all()]
        return SyncPullResponse(cursor=now, reports=reports, assignments=[])

    # Rescuer / admin: pull all updated incidents
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.updated_at > cursor)
        .order_by(Report.updated_at.asc())
        .limit(200)
    )
    reports = [await services.report_to_out(db, r) for r in result.scalars().all()]

    from app.infrastructure.models import Assignment

    asg = await db.execute(
        select(Assignment)
        .options(selectinload(Assignment.rescuer))
        .where(Assignment.updated_at > cursor)
        .limit(200)
    )
    assignments = [services.assignment_to_out(a) for a in asg.scalars().all()]
    return SyncPullResponse(cursor=now, reports=reports, assignments=assignments)


@router.post("/sms-inbound", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def sms_inbound(body: SmsInboundRequest, db: DbSession) -> ReportOut:
    settings = get_settings()
    if settings.sms_gateway_enabled and body.secret != settings.sms_inbound_secret:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid SMS secret")

    parsed = services.parse_sms_critical(body.raw_message)
    if parsed is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid SMS payload format")

    report = await services.create_report_from_sms(db, parsed)
    out = await services.report_to_out(db, report)
    await hub.broadcast_to_rescuers({"event": "incident.created", "data": out.model_dump(mode="json")})
    return out


@router.post("/media/{report_id}", status_code=status.HTTP_201_CREATED)
async def upload_media(
    report_id: UUID,
    db: DbSession,
    user: CurrentUser,
    file: UploadFile = File(...),
    sha256: str = Form(...),
) -> dict:
    result = await db.execute(select(Report).where(Report.id == report_id))
    report = result.scalar_one_or_none()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    if user.role == UserRole.citizen and report.citizen_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your report")

    content = await file.read()
    digest = hashlib.sha256(content).hexdigest()
    if digest != sha256:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="SHA-256 mismatch")

    ensure_bucket()
    object_key = f"evidence/{report_id}/{digest}"
    content_type = file.content_type or "application/octet-stream"
    put_object(object_key, content, content_type)

    existing = await db.execute(select(EvidenceMedia).where(EvidenceMedia.report_id == report_id))
    media = existing.scalar_one_or_none()
    if media is None:
        media = EvidenceMedia(
            report_id=report_id,
            content_type=content_type,
            object_key=object_key,
            size_bytes=len(content),
            sha256=digest,
        )
        db.add(media)
    else:
        media.object_key = object_key
        media.size_bytes = len(content)
        media.sha256 = digest
        media.content_type = content_type

    report.evidence_hash = digest
    if report.status.value == "queued":
        from app.schemas import ReportStatusUpdate
        from app.infrastructure.models import ReportStatus

        await services.update_report_status(
            db,
            report,
            ReportStatusUpdate(status=ReportStatus.received, note="Media synced after SMS/mesh"),
            user,
        )

    await db.flush()
    return {"report_id": str(report_id), "sha256": digest, "object_key": object_key, "size_bytes": len(content)}
