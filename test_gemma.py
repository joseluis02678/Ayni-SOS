import sys
import ollama

# Forzamos UTF-8 para la consola
sys.stdout.reconfigure(encoding='utf-8')

# 1. Definimos el Prompt del Sistema (Reglas de CENEPRED y Estructura)
PROMPT_SISTEMA = """
Eres el motor de triaje táctico offline de AyniSOS. Tu trabajo es leer reportes coloquiales de ciudadanos afectados por fenómenos naturales, traducirlos a lenguaje técnico y extraer la información clave.

REGLAS DE CLASIFICACIÓN (CENEPRED):
- CRÍTICO: 'Desastre' inminente con riesgo de vida. Daños que sobrepasan la respuesta local (ej. personas atrapadas, ahogamiento).
- URGENTE: 'Peligro Inminente' con alta probabilidad de impacto (ej. heridos moderados, necesidad médica pronta).
- ALTA: 'Vulnerabilidad' material expuesta. Daños a infraestructura sin riesgo de vida inmediato.

TRADUCCIÓN DE LENGUAJE COLOQUIAL A TÉCNICO:
- "Se vino el cerro / huaico" -> Deslizamiento / Flujo de detritos
- "El agua se salió / llegó al techo" -> Inundación Rápida
- "La pirca/pared se cayó" -> Colapso Estructural

INSTRUCCIÓN ESTRICTA:
Responde ÚNICAMENTE con un objeto JSON válido. No agregues saludos ni explicaciones. Usa esta estructura exacta:
{
  "prioridad": "CRÍTICO, URGENTE o ALTA",
  "tipo_tecnico": "Traducción técnica del evento",
  "ubicacion": "Extraer del texto (o null si no hay)",
  "personas_afectadas": "Extraer cantidad o descripción (o null si no hay)",
  "resumen_ia": "Resumen táctico de máximo 10 palabras"
}
"""

print("--- 🟢 Motor de Triaje AyniSOS (Gemma 4) Iniciado ---")
print("Escribe 'salir' para detener el script.\n")

# 2. Bucle interactivo para la consola
while True:
    # Capturamos el texto directamente desde la consola
    mensaje_ciudadano = input("🗣️ Ingresa el reporte del ciudadano: ")
    
    # Condición para salir del programa
    if mensaje_ciudadano.lower() in ['salir', 'exit']:
        print("Apagando motor de AyniSOS... ¡Éxitos en la hackatón!")
        break
        
    print("🤖 Gemma está evaluando la situación...")
    
    try:
        # 3. Llamada al modelo local
        response = ollama.chat(
            model='gemma4:e2b',
            messages=[
                {'role': 'system', 'content': PROMPT_SISTEMA},
                {'role': 'user', 'content': mensaje_ciudadano}
            ],
            format='json'
        )
        
        # 4. Imprimimos el resultado estructurado
        print("\n--- 📋 JSON para el Panel de Rescatista ---")
        print(response['message']['content'])
        print("-" * 50 + "\n")
        
    except Exception as e:
        print(f"❌ Ocurrió un error al procesar con Gemma: {e}\n")