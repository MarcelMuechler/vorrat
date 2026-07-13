# Vorrat

Self-hosted grocery & stock management.

## Configuration

No options. Data is stored in `/data/vorrat.db`.

## Access

- **Home Assistant UI**: use the "Vorrat" panel in the sidebar (via Ingress).
- **Mobile apps (Android/iOS)**: in the app's Settings tab, enter this server's LAN address,
  e.g. `http://<home-assistant-ip>:8099`.

There is no authentication in v1 — only use this on a trusted home network.
