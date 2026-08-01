# ADR-007: IA como recomendación

## Estado
Aceptado

## Contexto
Riesgo ético/legal de automatizar decisiones de rescate.

## Decisión
El agente genera `EmergencyAnalysis` con `ai_disclaimer: recommendation_only`.
Asignación y estados son acciones humanas del rescatista.

## Consecuencias
+ Transparencia y trazabilidad
- No hay dispatch automático
