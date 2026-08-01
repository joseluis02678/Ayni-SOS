# Dominio Ayni SOS

## Alcance
- Huaicos (landslide)
- Inundaciones (flood)
- Fenómeno de El Niño (el_nino_related)

## Fuera de alcance
Incendios, tránsito, delitos, emergencias médicas generales.

## Prioridad
1 = máxima urgencia … 5 = menor.

## Estados de reporte
draft → analyzing → pending_sync → queued|received → assigned → in_progress → resolved

## Canales de sync
- http — payload completo
- sms — crítico compacto AYNI|v1|…
- mesh — store-and-forward BLE/Wi-Fi Direct
