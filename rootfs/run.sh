#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting WireGuard Client add-on"

ENABLED=$(bashio::config 'enabled')
if ! bashio::var.true "${ENABLED}"; then
    bashio::log.info "Add-on is disabled via configuration. Exiting."
    exit 0
fi

INTERFACE_NAME=$(bashio::config 'interface_name')
PRIVATE_KEY=$(bashio::config 'private_key')
ADDRESS=$(bashio::config 'address')
DNS=$(bashio::config 'dns')

PEER_PUBLIC_KEY=$(bashio::config 'peer_public_key')
PEER_PRESHARED_KEY=$(bashio::config 'peer_preshared_key')
PEER_ENDPOINT=$(bashio::config 'peer_endpoint')
PEER_ALLOWED_IPS=$(bashio::config 'peer_allowed_ips')
PEER_PERSISTENT_KEEPALIVE=$(bashio::config 'peer_persistent_keepalive')

# Minimal-Checks
if [ -z "${PRIVATE_KEY}" ] || [ -z "${ADDRESS}" ] || [ -z "${PEER_PUBLIC_KEY}" ] || [ -z "${PEER_ENDPOINT}" ]; then
    bashio::log.error "Missing required configuration values (private_key, address, peer_public_key, peer_endpoint)."
    exit 1
fi

CONFIG_PATH="/etc/wireguard/${INTERFACE_NAME}.conf"
mkdir -p /etc/wireguard

bashio::log.info "Generating WireGuard config at ${CONFIG_PATH}"

cat > "${CONFIG_PATH}" <<EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${ADDRESS}
DNS = ${DNS}

[Peer]
PublicKey = ${PEER_PUBLIC_KEY}
PresharedKey = ${PEER_PRESHARED_KEY}
AllowedIPs = ${PEER_ALLOWED_IPS}
PersistentKeepalive = ${PEER_PERSISTENT_KEEPALIVE}
Endpoint = ${PEER_ENDPOINT}
EOF

bashio::log.info "Bringing up WireGuard interface: ${INTERFACE_NAME}"
wg-quick up "${CONFIG_PATH}"

finish() {
    bashio::log.info "Stopping WireGuard interface: ${INTERFACE_NAME}"
    wg-quick down "${CONFIG_PATH}" || true
    exit 0
}

trap finish SIGTERM SIGHUP

# Add-on am Leben halten
while true; do
    sleep 60
done
