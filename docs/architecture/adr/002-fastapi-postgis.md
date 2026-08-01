# ADR-002: FastAPI + PostgreSQL/PostGIS

## Estado
Aceptado

## Contexto
Backend debe exponer REST, WebSocket, sync idempotente y consultas geoespaciales.

## Decisión
FastAPI (async) + SQLAlchemy 2 + PostgreSQL 16/PostGIS + Redis + MinIO.

## Consecuencias
+ OpenAPI automático, tipado Pydantic, PostGIS nativo
+ Alineado con futuro ML server-side
- Requiere Docker o instancia Postgres local
