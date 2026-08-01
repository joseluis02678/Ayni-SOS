# ADR-001: Flutter sobre React Native

## Estado
Aceptado

## Contexto
Necesitamos IA on-device, mapas offline y mesh BLE/Wi-Fi Direct en un prototipo de investigación.

## Decisión
Usar Flutter 3.x con monorepo Melos (citizen_app + rescuer_app + packages).

## Consecuencias
+ Mejor integración con LiteRT-LM / MapLibre / mesh plugins
+ UI consistente bajo estrés
- Requiere toolchain Dart/Flutter en el equipo
