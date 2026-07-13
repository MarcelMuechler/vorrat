# Vorrat

Self-hosted household stock/inventory management — a Grocy alternative.

## Features

- Stock overview with best-before-date tracking
- Barcode scanning (Android, iOS, Web)
- Open Food Facts lookup for unknown products
- Deployable as a Home Assistant app, or standalone via Docker

## Layout

- `backend/` — FastAPI + SQLAlchemy + Alembic + SQLite REST API
- `frontend/` — Flutter app (Android, iOS, Web)
- `vorrat/` — Home Assistant app packaging (config, Dockerfile)
- `docs/` — architecture notes

## Development

```sh
# backend
cd backend && uv run uvicorn app.main:app --reload

# frontend (point Settings → Server URL at http://localhost:8000 once running,
# since the Flutter dev server and uvicorn are on different origins)
cd frontend && flutter build web && python3 -m http.server 8090 -d build/web
```

## Installing on Home Assistant

In Home Assistant, go to Settings → Add-ons → Add-on Store → ⋮ → Repositories, and add this
repo's URL. Install "Vorrat" from the store, start it, and open it from the sidebar. See
[`vorrat/DOCS.md`](vorrat/DOCS.md) for mobile app setup.

## Running standalone via Docker

```sh
docker build -f vorrat/Dockerfile -t vorrat .
docker run -d -p 8099:8099 -v vorrat-data:/data vorrat
```

No authentication in v1 — intended for a trusted home network / Home Assistant Ingress.
