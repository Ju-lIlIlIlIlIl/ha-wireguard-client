ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG BUILD_VERSION

# WireGuard-Tools installieren
RUN apk add --no-cache \
    wireguard-tools \
    iproute2-minimal

# rootfs in Container kopieren
COPY rootfs /

# run.sh ausführbar machen
RUN chmod +x /run.sh

# Start-Skript
CMD [ "/run.sh" ]
