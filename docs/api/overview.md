# API Overview

Base: `/api/v1`

| Method | Path | Role |
|--------|------|------|
| POST | /auth/register | public |
| POST | /auth/login | public |
| POST | /auth/refresh | public |
| GET | /auth/me | any |
| POST | /reports | citizen |
| GET | /reports/mine | citizen |
| GET | /reports/{id} | citizen/rescuer |
| GET | /incidents | rescuer |
| POST | /incidents/{id}/accept | rescuer |
| PATCH | /incidents/{id}/status | rescuer |
| GET | /incidents/{id}/assignees | rescuer |
| POST | /sync/push | any |
| GET | /sync/pull | any |
| POST | /sync/sms-inbound | gateway |
| POST | /sync/media/{id} | citizen |
| PATCH | /locations/rescuer | rescuer |
| WS | /ws/rescuer?token= | rescuer |

OpenAPI interactivo: `/docs`
