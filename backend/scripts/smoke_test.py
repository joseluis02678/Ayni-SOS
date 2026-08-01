"""End-to-end smoke test against a running Ayni SOS API."""

from __future__ import annotations

import hashlib
import sys
import uuid
from pathlib import Path

import httpx

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
API = f"{BASE}/api/v1"


def ok(label: str, cond: bool, detail: str = "") -> None:
    status = "PASS" if cond else "FAIL"
    print(f"[{status}] {label}" + (f" — {detail}" if detail else ""))
    if not cond:
        raise SystemExit(1)


def main() -> None:
    print(f"Smoke testing {BASE}\n")
    with httpx.Client(timeout=30.0) as client:
        # Health
        r = client.get(f"{BASE}/health")
        ok("health", r.status_code == 200 and r.json().get("status") == "ok", r.text)

        suffix = uuid.uuid4().hex[:8]
        citizen_email = f"ciudadano_{suffix}@example.com"
        rescuer_email = f"rescatista_{suffix}@example.com"

        # Register citizen
        r = client.post(
            f"{API}/auth/register",
            json={
                "email": citizen_email,
                "password": "ciudadano123",
                "full_name": "Ciudadano Prueba",
                "role": "citizen",
            },
        )
        ok("register citizen", r.status_code == 201, r.text)
        citizen = r.json()
        citizen_token = citizen["access_token"]

        # Register rescuer
        r = client.post(
            f"{API}/auth/register",
            json={
                "email": rescuer_email,
                "password": "rescatista123",
                "full_name": "Rescatista Prueba",
                "role": "rescuer",
            },
        )
        ok("register rescuer", r.status_code == 201, r.text)
        rescuer_token = r.json()["access_token"]

        # Login
        r = client.post(
            f"{API}/auth/login",
            json={"email": citizen_email, "password": "ciudadano123"},
        )
        ok("login citizen", r.status_code == 200, r.text)

        # Create report with AI analysis
        client_report_id = str(uuid.uuid4())
        report_body = {
            "client_report_id": client_report_id,
            "evidence_type": "photo",
            "latitude": -12.0464,
            "longitude": -77.0428,
            "accuracy_meters": 12.5,
            "evidence_hash": "deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcdef",
            "disaster_type": "landslide",
            "priority": 2,
            "summary": "Huaico cerca de viviendas",
            "sync_channel": "http",
            "ai_analysis": {
                "evidence_type": "photo",
                "disaster_type": "landslide",
                "transcription": None,
                "visual_analysis": {
                    "people_visible": 3,
                    "water_level": "medium",
                    "mud_present": True,
                    "landslide_visible": True,
                    "damaged_homes": 2,
                    "vehicles_affected": 1,
                    "obstacles": ["debris", "mud"],
                },
                "estimated_people": 5,
                "risk_level": "high",
                "suggested_resources": ["shovel_team", "ambulance"],
                "priority": 2,
                "summary": "Huaico con viviendas afectadas — recomendación IA",
                "confidence": 0.72,
                "ai_disclaimer": "recommendation_only",
            },
        }
        r = client.post(
            f"{API}/reports",
            headers={"Authorization": f"Bearer {citizen_token}"},
            json=report_body,
        )
        ok("create report", r.status_code == 201, r.text)
        report = r.json()
        report_id = report["id"]
        ok("report has AI analysis", report.get("ai_analysis") is not None)
        ok("priority from AI", report["priority"] == 2)

        # Idempotent recreate
        r = client.post(
            f"{API}/reports",
            headers={"Authorization": f"Bearer {citizen_token}"},
            json=report_body,
        )
        ok("idempotent report", r.status_code == 201 and r.json()["id"] == report_id)

        # Citizen history
        r = client.get(
            f"{API}/reports/mine",
            headers={"Authorization": f"Bearer {citizen_token}"},
        )
        ok("citizen history", r.status_code == 200 and len(r.json()) >= 1)

        # Rescuer incidents list
        r = client.get(
            f"{API}/incidents",
            headers={"Authorization": f"Bearer {rescuer_token}"},
        )
        ok("rescuer list incidents", r.status_code == 200 and any(i["id"] == report_id for i in r.json()))

        # Accept assignment
        r = client.post(
            f"{API}/incidents/{report_id}/accept",
            headers={"Authorization": f"Bearer {rescuer_token}"},
        )
        ok("accept incident", r.status_code == 201, r.text)
        assignment_id = r.json()["id"]

        # Assignees
        r = client.get(
            f"{API}/incidents/{report_id}/assignees",
            headers={"Authorization": f"Bearer {rescuer_token}"},
        )
        ok("assignee count", r.status_code == 200 and len(r.json()) == 1)

        # Update status
        r = client.patch(
            f"{API}/incidents/{report_id}/status",
            headers={"Authorization": f"Bearer {rescuer_token}"},
            json={"status": "in_progress", "note": "En camino"},
        )
        ok("status in_progress", r.status_code == 200 and r.json()["status"] == "in_progress")

        r = client.patch(
            f"{API}/incidents/{report_id}/status",
            headers={"Authorization": f"Bearer {rescuer_token}"},
            json={"status": "resolved", "note": "Rescate finalizado"},
        )
        ok("status resolved", r.status_code == 200 and r.json()["status"] == "resolved")

        # SMS inbound critical
        sms = "AYNI|v1|smstest1|-120464|-770428|1|L|abcd1234"
        r = client.post(
            f"{API}/sync/sms-inbound",
            json={"raw_message": sms, "secret": "ayni-sms-inbound-secret"},
        )
        ok("sms inbound", r.status_code == 201 and r.json()["sync_channel"] == "sms", r.text)
        ok("sms queued", r.json()["status"] == "queued")

        # Sync pull
        r = client.get(
            f"{API}/sync/pull",
            headers={"Authorization": f"Bearer {rescuer_token}"},
        )
        ok("sync pull", r.status_code == 200 and len(r.json().get("reports", [])) >= 1)

        # Media upload (local fallback)
        blob = b"fake-photo-bytes-for-ayni-sos-test"
        digest = hashlib.sha256(blob).hexdigest()
        r = client.post(
            f"{API}/sync/media/{report_id}",
            headers={"Authorization": f"Bearer {citizen_token}"},
            files={"file": ("evidence.jpg", blob, "image/jpeg")},
            data={"sha256": digest},
        )
        ok("media upload", r.status_code == 201 and r.json()["sha256"] == digest, r.text)

        # Rescuer location
        r = client.patch(
            f"{API}/locations/rescuer",
            headers={"Authorization": f"Bearer {rescuer_token}"},
            json={"latitude": -12.05, "longitude": -77.04},
        )
        ok("rescuer location", r.status_code == 200, r.text)

        # Assignment history
        r = client.get(
            f"{API}/assignments/mine",
            headers={"Authorization": f"Bearer {rescuer_token}"},
        )
        ok(
            "assignment history",
            r.status_code == 200 and any(a["id"] == assignment_id for a in r.json()),
        )

    print("\nAll smoke tests passed.")


if __name__ == "__main__":
    main()
