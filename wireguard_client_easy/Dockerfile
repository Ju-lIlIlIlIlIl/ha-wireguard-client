ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.19
FROM ${BUILD_FROM}

# Labels (optional, aber nice)
LABEL \
  io.hass.name="WireGuard Client (EasyConfig)" \
  io.hass.description="Einfacher WireGuard-Client für Home Assistant" \
  io.hass.version="0.1.0" \
  io.hass.type="addon" \
  io.hass.arch="amd64|aarch64|armv7"

# Pakete installieren: WireGuard Tools + Python + pip
RUN apk add --no-cache \
    wireguard-tools \
    python3 \
    py3-pip

# Flask installieren
RUN pip3 install --no-cache-dir flask

# rootfs in Container kopieren
COPY rootfs /

# Sicherstellen, dass run.sh ausführbar ist
RUN chmod +x /run.sh

# Start-Skript
CMD [ "/run.sh" ]
