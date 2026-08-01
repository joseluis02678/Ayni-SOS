# ADR-004: Offline-first con outbox

## Estado
Aceptado

## Contexto
La conectividad es intermitente durante desastres.

## Decisión
SQLite/JSON local como source of truth. Tabla `sync_outbox` con reintentos.
Pull por cursor `since`. Idempotencia por `client_report_id`.

## Consecuencias
+ Ciudadano siempre puede crear reportes
- Posibles conflictos LWW (aceptable en v1)
