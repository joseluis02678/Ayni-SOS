# Ayni-SOS
Motor de triaje Edge AI para emergencias 100% offline. Utiliza Gemma 4 local y Flutter para operar en zonas sin cobertura durante desastres naturales.

# 🚨 Ayni-SOS

> **Respuesta táctica y clasificación de emergencias sin conexión a internet mediante IA Edge (Gemma) y redes Mesh.**

---

## 📌 Tracks de la Competencia

* 🟢 **IA Local e Inteligencia Edge:** Procesamiento e inferencia 100% local en dispositivos móviles utilizando modelos **Gemma** optimizados.
* 🟢 **IA para Impacto Social:** Solución orientada a la gestión de riesgos y atención de desastres naturales (Fenómeno del Niño, huaicos), alineada con los Objetivos de Desarrollo Sostenible (ODS).

---

## 📸 Problema vs. Solución

### 🔴 El Problema
Durante catástrofes naturales como huaicos o inundaciones provocadas por el Fenómeno del Niño, las redes de telefonía celular e internet colapsan o se saturan por completo. 
* Las comunidades quedan aisladas e incomunicadas.
* Los equipos de rescate (bomberos, defensa civil) pierden visibilidad del terreno.
* Se imposibilita la priorización táctica de casos críticos (heridos de gravedad, personas atrapadas o colapsos estructurales) en las primeras horas decisivas.

### 🟢 La Solución: Ayni-SOS
**Ayni-SOS** es una aplicación móvil de arquitectura híbrida (perfil **Ciudadano** y perfil **Rescatista** en un solo paquete) que opera al **100% desconectada de internet**.

1. **Envío Offline:** Los ciudadanos envían reportes de emergencia con audio, datos y coordenadas GPS a través de redes locales de corto alcance (Wi-Fi Direct / Bluetooth).
2. **Inferencia Local (Edge AI):** El teléfono o nodo del equipo de rescate ejecuta el modelo **Gemma** directamente en el chip del dispositivo.
3. **Clasificación en Tiempo Real:** Gemma analiza al instante los datos e insumos (voz/texto) y clasifica automáticamente el nivel de peligro y la gravedad de los heridos.
4. **Mapeo Táctico:** La información procesada por Gemma se grafica automáticamente sobre un mapa *offline* integrado, permitiendo a los rescatistas tomar decisiones inmediatas sin cobertura.

---

## 📱 Flujo de Funcionamiento

```text
[📱 Ciudadano sin Internet]
       │
       ├─► Genera reporte (Audio / Texto / GPS)
       │
       ▼ (Transmisión mediante Wi-Fi Direct / Bluetooth)
[📡 Nodo de Comunicación / P2P]
       │
       ▼
[🚑 Dispositivo Rescatista / Bomberos]
       │
       ├─► Inferencia Local: Gemma (MediaPipe LLM API - INT4)
       ├─► Clasificación: Asignación de Nivel de Gravedad / Riesgo
       │
       ▼
[🗺️ Mapa Offline (OpenStreetMap)]
       └─► Marcado táctico de prioridades en tiempo real
```
