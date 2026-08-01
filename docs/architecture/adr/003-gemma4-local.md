# ADR-003: Gemma 4 E2B QAT mobile

## Estado
Aceptado

## Contexto
La IA debe ejecutarse localmente sin Internet y analizar audio o fotografía.

## Decisión
Modelo `gemma-4-E2B-it-qat-mobile` (~1.1 GB multimodal) vía `GemmaRuntime`.
En desarrollo se usa `HeuristicRuntime` que produce el mismo esquema JSON.

## Consecuencias
+ Offline real, privacidad de evidencias
- Requiere dispositivos ≥ ~4 GB RAM
- Integración nativa LiteRT-LM pendiente de FFI
