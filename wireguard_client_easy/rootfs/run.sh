#!/usr/bin/with-contenv bash
set -e

echo "[WG-CLIENT] Starte WireGuard Client Add-on..."

# Sicherstellen, dass /data existiert
mkdir -p /data

# Falls schon eine wg0.conf existiert: versuchen, Tunnel zu starten
if [ -f /data/wg0.conf ]; then
  echo "[WG-CLIENT] Gefundene Config: /data/wg0.conf – versuche Tunnel zu starten..."
  # Ignoriere Fehler bei 'down' (falls wg0 noch nicht existiert)
  wg-quick down wg0 2>/dev/null || true
  if wg-quick up /data/wg0.conf; then
    echo "[WG-CLIENT] WireGuard Tunnel wg0 gestartet."
  else
    echo "[WG-CLIENT] FEHLER: Konnte wg0 mit /data/wg0.conf nicht starten."
  fi
else
  echo "[WG-CLIENT] Noch keine /data/wg0.conf gefunden. Bitte im Web-UI hochladen."
fi

echo "[WG-CLIENT] Starte Web-UI (Flask)..."

# Flask Webserver starten (blockierend)
exec python3 /app/server.py
