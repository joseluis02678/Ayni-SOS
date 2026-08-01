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

##  🛠️ Tecnologías Utilizadas

- Motor de IA: Gemma 4 (Google) ejecutado vía Ollama.

- Backend Edge: Python 3.12, FastAPI.

- Frontend Móvil: Flutter (Dart).

- Mapas: Flutter Map, OpenStreetMap (Vector Tiles Offline).

- Datos Abiertos: Integración de JSON local con estadísticas de INABIF/INDECI.

## 🚀 Despliegue Rápido

1. Clonar el repositorio:
```
git clone [https://github.com/joseluis02678/ayni-sos.git](https://github.com/joseluis02678/ayni-sos.git)
cd ayni-sos
```

2. Iniciar el motor de IA local:
```
ollama serve
```

3. Instalar dependencias e iniciar el Backend:
```
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Desarrollado con ❤️ para Perú en el marco de la GDG AI Competition Lima 2026.

---

### 2. Archivo de Licencia (LICENSE)

Para cumplir con la recomendación de usar código abierto, debes crear un archivo en la raíz de tu proyecto llamado exactamente `LICENSE` (sin extensión) y pegar este texto. He incluido tu nombre completo y el año actual.

```text
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright 2026 Jose Luis Garay Ramos

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
