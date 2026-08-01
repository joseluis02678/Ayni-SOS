# Ayni SOS

Plataforma móvil inteligente para coordinación de rescates durante huaicos, inundaciones y eventos del Fenómeno de El Niño.

Prototipo de investigación: IA local (Gemma 4 E2B QAT), offline-first y comunicación resiliente (HTTP / SMS / Mesh).

## Arquitectura

```
ayni-sos/
├── apps/
│   ├── citizen_app/     # Flutter — ciudadanos
│   └── rescuer_app/     # Flutter — rescatistas
├── packages/
│   ├── core/            # Domain + use cases
│   ├── data/            # Repositorios local/remoto
│   ├── ai_engine/       # Agente Gemma 4 + validación JSON
│   ├── sync_engine/     # Outbox + transport router
│   ├── mesh_transport/  # BLE/Wi-Fi Direct abstraction
│   ├── geo_service/     # GPS + marcadores + MBTiles config
│   └── ui_kit/          # Design system
├── backend/             # FastAPI + PostgreSQL/PostGIS
├── infra/               # Docker, scripts
└── docs/                # ADRs, dominio, API
```

## Requisitos

- Python 3.11+
- Flutter 3.24+ (para apps móviles)
- Docker (PostgreSQL/PostGIS, Redis, MinIO) — opcional en desarrollo

## Backend

```bash
cd backend
docker compose up -d db redis minio   # si Docker está disponible
pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
```

Docs: http://localhost:8000/docs

## Apps Flutter

```bash
# Instalar Melos
dart pub global activate melos
melos bootstrap

# Ciudadano (emulador Android → API en 10.0.2.2:8000)
cd apps/citizen_app && flutter run

# Rescatista
cd apps/rescuer_app && flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Fases implementadas

| Fase | Contenido |
|------|-----------|
| 1 | Arquitectura (docs/architecture) |
| 2 | Scaffold monorepo + FastAPI + auth JWT + Docker |
| 3 | Citizen App MVP |
| 4 | AI Engine (Gemma runtime + heuristic fallback) |
| 5 | Sync Escenario 1 (HTTP + outbox) |
| 6 | Rescuer App (mapa MapLibre + WebSocket) |
| 7 | Asignación colaborativa + estados |
| 8 | Escenario 2 SMS crítico |
| 9 | Escenario 3 Mesh store-and-forward |
| 10 | Offline maps config + tests + pulido |

## Principios

- Clean Architecture / Repository / DI
- Offline-first (SQLite/JSON local → sync)
- IA solo recomienda; el rescatista decide
- Transportes intercambiables (ADR-005)
