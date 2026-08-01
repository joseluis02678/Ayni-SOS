# ADR-006: Dos apps independientes

## Estado
Aceptado

## Contexto
UX ciudadano (estrés, pocos botones) vs rescatista (dashboard profesional).

## Decisión
`citizen_app` y `rescuer_app` separadas; packages compartidos.

## Consecuencias
+ UX enfocada por rol
- Dos binarios que mantener
