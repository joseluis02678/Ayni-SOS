"""SQLAlchemy ORM models for Ayni SOS (Postgres + SQLite portable)."""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def _enum(enum_cls: type[enum.Enum], name: str):
    """String enums work on both PostgreSQL and SQLite."""
    return Enum(enum_cls, name=name, native_enum=False, values_callable=lambda x: [e.value for e in x])


class UserRole(str, enum.Enum):
    citizen = "citizen"
    rescuer = "rescuer"
    admin = "admin"


class EvidenceType(str, enum.Enum):
    audio = "audio"
    photo = "photo"


class DisasterType(str, enum.Enum):
    landslide = "landslide"
    flood = "flood"
    el_nino_related = "el_nino_related"


class ReportStatus(str, enum.Enum):
    draft = "draft"
    analyzing = "analyzing"
    pending_sync = "pending_sync"
    queued = "queued"
    received = "received"
    assigned = "assigned"
    in_progress = "in_progress"
    resolved = "resolved"
    cancelled = "cancelled"


class RiskLevel(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class AssignmentStatus(str, enum.Enum):
    accepted = "accepted"
    en_route = "en_route"
    on_scene = "on_scene"
    completed = "completed"
    withdrawn = "withdrawn"


class SyncChannel(str, enum.Enum):
    http = "http"
    sms = "sms"
    mesh = "mesh"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(_enum(UserRole, "user_role"), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    reports: Mapped[list[Report]] = relationship(back_populates="citizen")
    assignments: Mapped[list[Assignment]] = relationship(back_populates="rescuer")


class Report(Base):
    __tablename__ = "reports"
    __table_args__ = (UniqueConstraint("client_report_id", name="uq_reports_client_report_id"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_report_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), nullable=False, index=True)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    evidence_type: Mapped[EvidenceType] = mapped_column(_enum(EvidenceType, "evidence_type"))
    disaster_type: Mapped[DisasterType | None] = mapped_column(
        _enum(DisasterType, "disaster_type"), nullable=True
    )
    status: Mapped[ReportStatus] = mapped_column(
        _enum(ReportStatus, "report_status"), default=ReportStatus.received
    )
    priority: Mapped[int] = mapped_column(Integer, default=3, index=True)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    # WKT text fallback for SQLite; PostGIS Geography can be restored in prod migrations
    location: Mapped[str | None] = mapped_column(String(128), nullable=True)
    accuracy_meters: Mapped[float | None] = mapped_column(Float, nullable=True)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    evidence_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)
    sync_channel: Mapped[SyncChannel | None] = mapped_column(
        _enum(SyncChannel, "sync_channel"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    citizen: Mapped[User] = relationship(back_populates="reports")
    ai_analysis: Mapped[AiAnalysis | None] = relationship(back_populates="report", uselist=False)
    evidence_media: Mapped[EvidenceMedia | None] = relationship(back_populates="report", uselist=False)
    status_history: Mapped[list[ReportStatusHistory]] = relationship(back_populates="report")
    assignments: Mapped[list[Assignment]] = relationship(back_populates="report")


class AiAnalysis(Base):
    __tablename__ = "ai_analyses"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("reports.id"), unique=True, nullable=False)
    structured_report: Mapped[dict] = mapped_column(JSON, nullable=False)
    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    risk_level: Mapped[RiskLevel | None] = mapped_column(_enum(RiskLevel, "risk_level"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    report: Mapped[Report] = relationship(back_populates="ai_analysis")


class EvidenceMedia(Base):
    __tablename__ = "evidence_media"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("reports.id"), unique=True, nullable=False)
    content_type: Mapped[str] = mapped_column(String(128), nullable=False)
    object_key: Mapped[str] = mapped_column(String(512), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, default=0)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    report: Mapped[Report] = relationship(back_populates="evidence_media")


class ReportStatusHistory(Base):
    __tablename__ = "report_status_history"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("reports.id"), nullable=False, index=True)
    from_status: Mapped[ReportStatus | None] = mapped_column(
        _enum(ReportStatus, "report_status"), nullable=True
    )
    to_status: Mapped[ReportStatus] = mapped_column(_enum(ReportStatus, "report_status"), nullable=False)
    changed_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    report: Mapped[Report] = relationship(back_populates="status_history")


class Assignment(Base):
    __tablename__ = "assignments"
    __table_args__ = (UniqueConstraint("report_id", "rescuer_id", name="uq_assignment_report_rescuer"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("reports.id"), nullable=False, index=True)
    rescuer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    status: Mapped[AssignmentStatus] = mapped_column(
        _enum(AssignmentStatus, "assignment_status"), default=AssignmentStatus.accepted
    )
    accepted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    report: Mapped[Report] = relationship(back_populates="assignments")
    rescuer: Mapped[User] = relationship(back_populates="assignments")


class RescueTeam(Base):
    __tablename__ = "rescue_teams"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    region: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class TeamMember(Base):
    __tablename__ = "team_members"
    __table_args__ = (UniqueConstraint("team_id", "user_id", name="uq_team_user"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    team_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rescue_teams.id"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)


class RescuerLocation(Base):
    __tablename__ = "rescuer_locations"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rescuer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class SyncCursor(Base):
    __tablename__ = "sync_cursors"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    device_id: Mapped[str] = mapped_column(String(128), nullable=False)
    cursor: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
