# Ayni SOS

> Respuesta táctica y clasificación de emergencias sin conexión a internet mediante IA Edge (Gemma) y redes Mesh.

Plataforma móvil para coordinación de rescates durante **huaicos**, **inundaciones** y eventos del **Fenómeno de El Niño**.

---

## Tracks de la Competencia

* **IA Local e Inteligencia Edge:** Inferencia 100% local en dispositivos móviles con modelos **Gemma** cuantizados.
* **IA para Impacto Social:** Gestión de riesgos y desastres naturales, alineada con los ODS.

---

## Problema vs. Solución

### El Problema

Durante catástrofes (huaicos / inundaciones por El Niño), las redes colapsan:

* Comunidades aisladas e incomunicadas
* Equipos de rescate sin visibilidad del terreno
* Sin priorización táctica en las primeras horas críticas

### La Solución: Ayni SOS

Arquitectura con perfiles **Ciudadano** y **Rescatista**:

1. **Envío resiliente:** reportes con audio o foto + GPS (HTTP / SMS crítico / Mesh)
2. **Inferencia local (Edge AI):** Gemma 4 E2B QAT en el dispositivo (recomendación, no decisión final)
3. **Clasificación estructurada:** prioridad, riesgo y recursos sugeridos
4. **Mapa táctico:** incidentes georreferenciados para el rescatista (MapLibre / OSM)

---

## Flujo

```text
[Ciudadano]
   │  Audio o Foto + GPS
   ▼
[IA local Gemma / heurística]
   │  Reporte estructurado JSON
   ▼
[Outbox + TransportRouter]
   │  HTTP | SMS | Mesh
   ▼
[Backend FastAPI]
   ▼
[App Rescatista — mapa / asignación / seguimiento]
```

---

## Estructura del repositorio

```text
ayni-sos/
├── apps/
│   ├── citizen_app/      # Flutter — ciudadanos
│   ├── rescuer_app/      # Flutter — rescatistas
│   └── web_preview/      # Vista web de prueba
├── packages/             # core, data, ai_engine, sync_engine, mesh, geo, ui_kit
├── backend/              # FastAPI + SQLite/Postgres
├── infra/                # Docker, scripts
└── docs/                 # ADRs, dominio, guía móvil
```

---

## Despliegue rápido

### Backend

```bash
cd backend
cp .env.example .env
pip install -e ".[dev]"
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### Vista web de prueba

```bash
cd apps/web_preview
python -m http.server 5500
```

Abrir http://127.0.0.1:5500/

### Apps Flutter

```bash
# Requiere Flutter SDK
cd apps/citizen_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

cd ../rescuer_app
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Guía detallada: [docs/mobile_run.md](docs/mobile_run.md) · Arquitectura: [docs/architecture/](docs/architecture/)

---

## Tecnologías

| Capa | Stack |
|------|--------|
| IA | Gemma 4 E2B QAT (LiteRT / heurística en prototipo) |
| Móvil | Flutter (Dart) |
| Backend | Python, FastAPI, SQLAlchemy |
| Datos | SQLite local / PostgreSQL+PostGIS |
| Mapas | MapLibre + OpenStreetMap |
| Sync | HTTP, SMS crítico, Mesh store-and-forward |

---

## Licencia

Apache License 2.0 — ver [LICENSE](LICENSE).

Desarrollado para Perú en el marco de la GDG AI Competition Lima 2026.
Grupo SGD
