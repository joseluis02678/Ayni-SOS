"""Domain services for reports, assignments, and sync."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.infrastructure.models import (
    AiAnalysis,
    Assignment,
    AssignmentStatus,
    Report,
    ReportStatus,
    ReportStatusHistory,
    RescuerLocation,
    SyncChannel,
    User,
)
from app.schemas import (
    AssignmentOut,
    EmergencyAnalysisReport,
    ReportCreate,
    ReportOut,
    ReportStatusUpdate,
)


def _point_geog(lon: float, lat: float) -> str:
    """Store WKT as text (portable). PostGIS Geography can wrap this in prod."""
    return f"POINT({lon} {lat})"


async def create_or_get_report(db: AsyncSession, citizen: User, data: ReportCreate) -> tuple[Report, bool]:
    """Idempotent report creation by client_report_id. Returns (report, created)."""
    existing = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.client_report_id == data.client_report_id)
    )
    report = existing.scalar_one_or_none()
    if report is not None:
        return report, False

    report = Report(
        client_report_id=data.client_report_id,
        citizen_id=citizen.id,
        evidence_type=data.evidence_type,
        disaster_type=data.disaster_type,
        status=ReportStatus.received,
        priority=data.priority,
        latitude=data.latitude,
        longitude=data.longitude,
        accuracy_meters=data.accuracy_meters,
        summary=data.summary,
        evidence_hash=data.evidence_hash,
        sync_channel=data.sync_channel,
        location=_point_geog(data.longitude, data.latitude),
    )
    db.add(report)
    await db.flush()

    db.add(
        ReportStatusHistory(
            report_id=report.id,
            from_status=None,
            to_status=ReportStatus.received,
            changed_by=citizen.id,
            note=f"Received via {data.sync_channel.value}",
        )
    )

    if data.ai_analysis is not None:
        analysis = data.ai_analysis
        db.add(
            AiAnalysis(
                report_id=report.id,
                structured_report=analysis.model_dump(mode="json"),
                confidence=analysis.confidence,
                risk_level=analysis.risk_level,
            )
        )
        report.priority = analysis.priority
        report.disaster_type = analysis.disaster_type
        report.summary = analysis.summary

    await db.flush()
    return report, True


async def report_to_out(db: AsyncSession, report: Report) -> ReportOut:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .where(Report.id == report.id)
    )
    report = result.scalar_one()
    ai_out = None
    if report.ai_analysis is not None:
        ai_out = EmergencyAnalysisReport.model_validate(report.ai_analysis.structured_report)
    return ReportOut(
        id=report.id,
        client_report_id=report.client_report_id,
        citizen_id=report.citizen_id,
        evidence_type=report.evidence_type,
        disaster_type=report.disaster_type,
        status=report.status,
        priority=report.priority,
        latitude=report.latitude,
        longitude=report.longitude,
        accuracy_meters=report.accuracy_meters,
        summary=report.summary,
        evidence_hash=report.evidence_hash,
        sync_channel=report.sync_channel,
        created_at=report.created_at,
        updated_at=report.updated_at,
        ai_analysis=ai_out,
        assignee_count=len(report.assignments) if report.assignments else 0,
    )


async def list_incidents(
    db: AsyncSession,
    *,
    min_lat: float | None = None,
    max_lat: float | None = None,
    min_lon: float | None = None,
    max_lon: float | None = None,
    status: ReportStatus | None = None,
    priority_min: int | None = None,
    disaster_type: Any = None,
    limit: int = 100,
) -> list[ReportOut]:
    stmt = (
        select(Report)
        .options(selectinload(Report.ai_analysis), selectinload(Report.assignments))
        .order_by(Report.priority.asc(), Report.created_at.desc())
        .limit(limit)
    )
    filters = []
    if status is not None:
        filters.append(Report.status == status)
    if priority_min is not None:
        filters.append(Report.priority <= priority_min)  # lower number = higher priority
    if disaster_type is not None:
        filters.append(Report.disaster_type == disaster_type)
    if min_lat is not None:
        filters.append(Report.latitude >= min_lat)
    if max_lat is not None:
        filters.append(Report.latitude <= max_lat)
    if min_lon is not None:
        filters.append(Report.longitude >= min_lon)
    if max_lon is not None:
        filters.append(Report.longitude <= max_lon)
    if filters:
        stmt = stmt.where(and_(*filters))

    result = await db.execute(stmt)
    reports = result.scalars().all()
    return [await report_to_out(db, r) for r in reports]


async def update_report_status(
    db: AsyncSession,
    report: Report,
    update: ReportStatusUpdate,
    actor: User,
) -> Report:
    old = report.status
    report.status = update.status
    db.add(
        ReportStatusHistory(
            report_id=report.id,
            from_status=old,
            to_status=update.status,
            changed_by=actor.id,
            note=update.note,
        )
    )
    await db.flush()
    return report


async def accept_assignment(db: AsyncSession, report: Report, rescuer: User) -> Assignment:
    existing = await db.execute(
        select(Assignment).where(
            Assignment.report_id == report.id,
            Assignment.rescuer_id == rescuer.id,
        )
    )
    assignment = existing.scalar_one_or_none()
    if assignment is not None:
        return assignment

    assignment = Assignment(
        report_id=report.id,
        rescuer_id=rescuer.id,
        status=AssignmentStatus.accepted,
    )
    db.add(assignment)
    if report.status in (ReportStatus.received, ReportStatus.queued):
        await update_report_status(
            db,
            report,
            ReportStatusUpdate(status=ReportStatus.assigned, note="Rescuer accepted"),
            rescuer,
        )
    await db.flush()
    return assignment


async def count_assignees(db: AsyncSession, report_id: uuid.UUID) -> int:
    result = await db.execute(
        select(func.count()).select_from(Assignment).where(Assignment.report_id == report_id)
    )
    return int(result.scalar_one())


async def upsert_rescuer_location(
    db: AsyncSession, rescuer: User, latitude: float, longitude: float
) -> RescuerLocation:
    result = await db.execute(select(RescuerLocation).where(RescuerLocation.rescuer_id == rescuer.id))
    loc = result.scalar_one_or_none()
    if loc is None:
        loc = RescuerLocation(rescuer_id=rescuer.id, latitude=latitude, longitude=longitude)
        db.add(loc)
    else:
        loc.latitude = latitude
        loc.longitude = longitude
        loc.updated_at = datetime.now(UTC)
    await db.flush()
    return loc


DISASTER_CODES = {
    "L": "landslide",
    "F": "flood",
    "N": "el_nino_related",
}


def parse_sms_critical(raw: str) -> dict[str, Any] | None:
    """Parse AYNI|v1|{id}|{lat}|{lon}|{pri}|{code}|{hash} compact SMS."""
    parts = raw.strip().split("|")
    if len(parts) < 8 or parts[0] != "AYNI":
        return None
    try:
        lat = int(parts[3]) / 10000.0
        lon = int(parts[4]) / 10000.0
        return {
            "version": parts[1],
            "report_id_short": parts[2],
            "latitude": lat,
            "longitude": lon,
            "priority": int(parts[5]),
            "disaster_code": parts[6],
            "evidence_hash_8": parts[7],
            "disaster_type": DISASTER_CODES.get(parts[6]),
        }
    except (ValueError, IndexError):
        return None


async def create_report_from_sms(
    db: AsyncSession,
    parsed: dict[str, Any],
    citizen: User | None = None,
) -> Report:
    """Create a queued report from SMS critical payload (media deferred)."""
    short = parsed["report_id_short"]
    # Reconstruct a deterministic UUID namespace from short id for idempotency
    client_id = uuid.uuid5(uuid.NAMESPACE_URL, f"ayni-sms:{short}")

    existing = await db.execute(select(Report).where(Report.client_report_id == client_id))
    report = existing.scalar_one_or_none()
    if report is not None:
        return report

    # System placeholder citizen if unknown
    if citizen is None:
        result = await db.execute(select(User).where(User.email == "sms-gateway@ayni.local"))
        citizen = result.scalar_one_or_none()
        if citizen is None:
            from app.core.security import hash_password
            from app.infrastructure.models import UserRole

            citizen = User(
                email="sms-gateway@ayni.local",
                full_name="SMS Gateway",
                password_hash=hash_password(str(uuid.uuid4())),
                role=UserRole.citizen,
            )
            db.add(citizen)
            await db.flush()

    from app.infrastructure.models import DisasterType, EvidenceType

    disaster = None
    if parsed.get("disaster_type"):
        disaster = DisasterType(parsed["disaster_type"])

    report = Report(
        client_report_id=client_id,
        citizen_id=citizen.id,
        evidence_type=EvidenceType.photo,  # unknown until media sync
        disaster_type=disaster,
        status=ReportStatus.queued,
        priority=parsed["priority"],
        latitude=parsed["latitude"],
        longitude=parsed["longitude"],
        evidence_hash=parsed["evidence_hash_8"],
        sync_channel=SyncChannel.sms,
        summary=f"Critical SMS alert (hash={parsed['evidence_hash_8']})",
        location=_point_geog(parsed["longitude"], parsed["latitude"]),
    )
    db.add(report)
    await db.flush()
    db.add(
        ReportStatusHistory(
            report_id=report.id,
            from_status=None,
            to_status=ReportStatus.queued,
            changed_by=citizen.id,
            note="Received via SMS critical channel",
        )
    )
    await db.flush()
    return report


def assignment_to_out(assignment: Assignment, rescuer_name: str | None = None) -> AssignmentOut:
    name = rescuer_name
    if name is None:
        try:
            name = assignment.rescuer.full_name if assignment.rescuer else None
        except Exception:  # noqa: BLE001 — avoid lazy IO in async
            name = None
    return AssignmentOut(
        id=assignment.id,
        report_id=assignment.report_id,
        rescuer_id=assignment.rescuer_id,
        rescuer_name=name,
        status=assignment.status,
        accepted_at=assignment.accepted_at,
        updated_at=assignment.updated_at,
    )
