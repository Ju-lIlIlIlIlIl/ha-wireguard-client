#!/usr/bin/with-contenv bashio
# WireGuard Client Add-on

set -e

CONFIG_PATH=/data/options.json

bashio::log.info "Starting WireGuard Client add-on"

# --- Config aus HA-Options lesen ---
PRIVATE_KEY=$(bashio::config 'private_key')
ADDRESS=$(bashio::config 'address')
DNS=$(bashio::config 'dns')
PUBLIC_KEY=$(bashio::config 'public_key')
PRESHARED_KEY=$(bashio::config 'preshared_key')
ENDPOINT=$(bashio::config 'endpoint')
ALLOWED_IPS=$(bashio::config 'allowed_ips')

# Minimal-Validierung
if bashio::var.is_empty "${PRIVATE_KEY}"; then
  bashio::log.error "private_key is empty – please fill in add-on options."
  exit 1
fi

if bashio::var.is_empty "${ADDRESS}"; then
  bashio::log.error "address is empty – please fill in add-on options."
  exit 1
fi

if bashio::var.is_empty "${PUBLIC_KEY}"; then
  bashio::log.error "public_key is empty – please fill in add-on options."
  exit 1
fi

if bashio::var.is_empty "${ENDPOINT}"; then
  bashio::log.error "endpoint is empty – please fill in add-on options."
  exit 1
fi

if bashio::var.is_empty "${ALLOWED_IPS}"; then
  ALLOWED_IPS="0.0.0.0/0"
  bashio::log.info "allowed_ips not set – defaulting to ${ALLOWED_IPS}"
fi

bashio::log.info "Generating WireGuard config at /etc/wireguard/client.conf"

# --- client.conf schreiben ---
CONFIG_FILE="/etc/wireguard/client.conf"

{
  echo "[Interface]"
  echo "PrivateKey = ${PRIVATE_KEY}"
  echo "Address = ${ADDRESS}"
  # DNS NUR schreiben, wenn gesetzt → vermeidet resolvconf-Probleme
  if ! bashio::var.is_empty "${DNS}"; then
    echo "DNS = ${DNS}"
  fi
  echo ""
  echo "[Peer]"
  echo "PublicKey = ${PUBLIC_KEY}"
  if ! bashio::var.is_empty "${PRESHARED_KEY}"; then
    echo "PresharedKey = ${PRESHARED_KEY}"
  fi
  echo "AllowedIPs = ${ALLOWED_IPS}"
  echo "PersistentKeepalive = 25"
  echo "Endpoint = ${ENDPOINT}"
} > "${CONFIG_FILE}"

bashio::log.info "Bringing up WireGuard interface: client"
wg-quick up client

bashio::log.info "WireGuard client started successfully."

# --- einfacher Status-Loop für Logs ---
while true; do
  bashio::log.info "WireGuard status:"
  wg show client || bashio::log.warning "wg show client failed"
  sleep 30
done
