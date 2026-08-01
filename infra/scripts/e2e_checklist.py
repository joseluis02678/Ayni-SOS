"""Offline map helper notes and E2E checklist for Phase 10."""

# Manual E2E checklist (prototype)
CHECKLIST = """
[ ] Register citizen + rescuer
[ ] Citizen: capture photo, see AI analysis, report pending_sync → received
[ ] Kill network: create report, verify outbox queues
[ ] Restore network: processOutbox syncs without duplicates (same client_report_id)
[ ] SMS: POST /sync/sms-inbound with AYNI|v1|...
[ ] Mesh: InMemoryMeshNetwork relays critical payload between simulated peers
[ ] Rescuer: map shows markers by priority; accept assignment; update status
[ ] WebSocket: second rescuer receives incident.created
[ ] Offline map: place MBTiles and load via mbtiles:// protocol
"""
