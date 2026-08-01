"""Pydantic request/response schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.infrastructure.models import (
    AssignmentStatus,
    DisasterType,
    EvidenceType,
    ReportStatus,
    RiskLevel,
    SyncChannel,
    UserRole,
)


# ── Auth ──────────────────────────────────────────────────────────────────────


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=255)
    phone: str | None = None
    role: UserRole = UserRole.citizen


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: UUID
    role: UserRole
    full_name: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str
    phone: str | None
    role: UserRole
    created_at: datetime

    model_config = {"from_attributes": True}


# ── AI Analysis ───────────────────────────────────────────────────────────────


class VisualAnalysis(BaseModel):
    people_visible: int = 0
    water_level: str = "none"
    mud_present: bool = False
    landslide_visible: bool = False
    damaged_homes: int = 0
    vehicles_affected: int = 0
    obstacles: list[str] = Field(default_factory=list)


class EmergencyAnalysisReport(BaseModel):
    report_id: UUID | None = None
    evidence_type: EvidenceType
    disaster_type: DisasterType
    transcription: str | None = None
    visual_analysis: VisualAnalysis | None = None
    estimated_people: int = 0
    risk_level: RiskLevel
    suggested_resources: list[str] = Field(default_factory=list)
    priority: int = Field(ge=1, le=5)
    summary: str
    confidence: float = Field(ge=0.0, le=1.0)
    ai_disclaimer: str = "recommendation_only"


# ── Reports ───────────────────────────────────────────────────────────────────


class ReportCreate(BaseModel):
    client_report_id: UUID
    evidence_type: EvidenceType
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    accuracy_meters: float | None = None
    evidence_hash: str | None = None
    disaster_type: DisasterType | None = None
    priority: int = Field(default=3, ge=1, le=5)
    summary: str | None = None
    ai_analysis: EmergencyAnalysisReport | None = None
    sync_channel: SyncChannel = SyncChannel.http


class ReportStatusUpdate(BaseModel):
    status: ReportStatus
    note: str | None = None


class ReportOut(BaseModel):
    id: UUID
    client_report_id: UUID
    citizen_id: UUID
    evidence_type: EvidenceType
    disaster_type: DisasterType | None
    status: ReportStatus
    priority: int
    latitude: float
    longitude: float
    accuracy_meters: float | None
    summary: str | None
    evidence_hash: str | None
    sync_channel: SyncChannel | None
    created_at: datetime
    updated_at: datetime
    ai_analysis: EmergencyAnalysisReport | None = None
    assignee_count: int = 0

    model_config = {"from_attributes": True}


class IncidentListQuery(BaseModel):
    min_lat: float | None = None
    max_lat: float | None = None
    min_lon: float | None = None
    max_lon: float | None = None
    status: ReportStatus | None = None
    priority_min: int | None = None
    disaster_type: DisasterType | None = None


# ── Assignments ───────────────────────────────────────────────────────────────


class AssignmentOut(BaseModel):
    id: UUID
    report_id: UUID
    rescuer_id: UUID
    rescuer_name: str | None = None
    status: AssignmentStatus
    accepted_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class AssignmentStatusUpdate(BaseModel):
    status: AssignmentStatus
    note: str | None = None


# ── Sync ──────────────────────────────────────────────────────────────────────


class SyncPushItem(BaseModel):
    operation: str  # create_report | update_status | upload_media_meta
    payload: dict[str, Any]
    client_id: UUID
    created_at: datetime


class SyncPushRequest(BaseModel):
    device_id: str
    items: list[SyncPushItem]


class SyncPushResponse(BaseModel):
    accepted: list[UUID]
    rejected: list[dict[str, Any]]


class SyncPullResponse(BaseModel):
    cursor: datetime
    reports: list[ReportOut]
    assignments: list[AssignmentOut]


class SmsInboundRequest(BaseModel):
    """Compact SMS critical payload decoded by gateway."""

    raw_message: str
    from_phone: str | None = None
    secret: str | None = None


class SmsCriticalPayload(BaseModel):
    version: str = "v1"
    report_id_short: str
    client_report_id: UUID | None = None
    latitude: float
    longitude: float
    priority: int
    disaster_code: str
    evidence_hash_8: str


# ── Location ──────────────────────────────────────────────────────────────────


class RescuerLocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
