# Ayni SOS Backend

Research prototype API for disaster rescue coordination (huaicos, inundations, El Niño).

## Quick start

```bash
# From repo root — start infrastructure
cd backend
docker compose up -d db redis minio

# Install & run API locally
pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
```

OpenAPI docs: http://localhost:8000/docs

## Auth

- `POST /api/v1/auth/register` — citizen or rescuer
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`

## Key modules

| Prefix | Purpose |
|--------|---------|
| `/auth` | Registration, JWT sessions |
| `/reports` | Citizen evidence reports |
| `/incidents` | Rescuer map/list views |
| `/sync` | Offline-first push/pull, SMS inbound, media |
| `/ws/rescuer` | Real-time incident events |
