# ADR-005: Transport router desacoplado

## Estado
Aceptado

## Contexto
Tres escenarios: Internet, solo celular, sin cobertura.

## Decisión
Interfaz `SyncTransport` con implementaciones `HttpTransport`, `SmsTransport`, `MeshTransportAdapter`.
`TransportRouter` elige HTTP > SMS > Mesh.

## Consecuencias
+ Reemplazo de tecnologías sin tocar dominio
- Complejidad de pruebas multi-transporte
