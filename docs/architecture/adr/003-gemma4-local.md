# ADR-003: Gemma 4 local (LiteRT-LM)

## Estado
Aceptado (integración nativa en progreso)

## Contexto
Inferencia 100% on-device para evidencia (audio/foto) sin depender de la nube en el momento del desastre.

## Decisión
- Runtime abstracto `GemmaRuntime` + `EmergencyAgent` (JSON estructurado, recommendation-only).
- Producción Android: **LiteRT-LM** vía MethodChannel `pe.ayni.sos/gemma` (Engine + Conversation).
- Desarrollo / sin modelo: `HeuristicRuntime` (mismo esquema JSON).
- Fallback automático: `FallbackGemmaRuntime` (LiteRT → heurística).
- Modelo: `gemma-4-E2B-it.litertlm` (~2.6 GB) en documentos de la app o `GEMMA_MODEL_PATH`.

## Consecuencias
+ Misma API Dart para IA real o mock
+ Citizen app minSdk 31 (requisito LiteRT-LM)
- Descarga del modelo fuera del APK (script `infra/scripts/download_gemma_model.ps1`)
- Sin modelo instalado, el flujo sigue con heurística
