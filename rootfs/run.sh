#!/usr/bin/with-contenv bashio
set -e

WG_CONF="/etc/wireguard/client.conf"
WG_INTERFACE="client"
STATUS_FILE="/config/wireguard_client_status.json"

bashio::log.info "Starting WireGuard Client add-on"

# --- Optionen aus /data/options.json lesen ---
PRIVATE_KEY=$(bashio::config 'private_key')
ADDRESS=$(bashio::config 'address')
PUBLIC_KEY=$(bashio::config 'public_key')
PRESHARED_KEY=$(bashio::config 'preshared_key')
ENDPOINT=$(bashio::config 'endpoint')
ALLOWED_IPS=$(bashio::config 'allowed_ips')
PERSISTENT_KEEPALIVE="$(jq -r '.persistent_keepalive // empty' /data/options.json)"

# --- Konfig prüfen ---
if [ -z "$PRIVATE_KEY" ] || [ -z "$ADDRESS" ] || [ -z "$PUBLIC_KEY" ] || [ -z "$ENDPOINT" ]; then
  bashio::log.fatal "private_key, address, public_key and endpoint must be set!"
  exit 1
fi

if [ -z "$ALLOWED_IPS" ]; then
  bashio::log.warning "allowed_ips is empty – using default 0.0.0.0/0"
  ALLOWED_IPS="0.0.0.0/0"
fi

if [ -z "$PERSISTENT_KEEPALIVE" ] || [ "$PERSISTENT_KEEPALIVE" = "null" ]; then
  PERSISTENT_KEEPALIVE="25"
fi

# --- WireGuard config schreiben (ohne DNS!) ---
bashio::log.info "Generating WireGuard config at ${WG_CONF}"

{
  echo "[Interface]"
  echo "PrivateKey = ${PRIVATE_KEY}"
  echo "Address = ${ADDRESS}"
  echo ""
  echo "[Peer]"
  if [ -n "$PRESHARED_KEY" ]; then
    echo "PresharedKey = ${PRESHARED_KEY}"
  fi
  echo "PublicKey = ${PUBLIC_KEY}"
  echo "AllowedIPs = ${ALLOWED_IPS}"
  echo "Endpoint = ${ENDPOINT}"
  echo "PersistentKeepalive = ${PERSISTENT_KEEPALIVE}"
} > "${WG_CONF}"

bashio::log.info "Resulting WireGuard config (for debugging):"
sed 's/^\(PrivateKey = \).*/\1****/; s/^\(PresharedKey = \).*/\1****/' "${WG_CONF}" \
  || bashio::log.warning "Unable to print redacted config"

# --- Interface ggf. aufräumen ---
if ip link show "${WG_INTERFACE}" >/dev/null 2>&1; then
  bashio::log.warning "Interface '${WG_INTERFACE}' already exists – deleting it first"
  wg-quick down "${WG_INTERFACE}" || true
fi

# --- WireGuard Interface hochfahren ---
bashio::log.info "Bringing up WireGuard interface: ${WG_INTERFACE}"
wg-quick up "${WG_INTERFACE}"

# --- Status-Datei vorbereiten ---
if [ ! -f "${STATUS_FILE}" ]; then
  bashio::log.info "Creating initial status file at ${STATUS_FILE}"
  echo '{"state":"starting","latest_handshake":null,"rx":null,"tx":null,"updated_at":null}' > "${STATUS_FILE}" || true
fi

# --- Status in JSON schreiben ---
update_status_json() {
  local status
  status="$(wg show "${WG_INTERFACE}" 2>/dev/null || true)"

  if [ -z "$status" ]; then
    cat > "${STATUS_FILE}" <<EOF || true
{
  "state": "disconnected",
  "latest_handshake": null,
  "rx": null,
  "tx": null,
  "updated_at": "$(date -Iseconds)"
}
EOF
    return
  fi

  local latest
  latest="$(printf '%s\n' "$status" | awk '/latest handshake:/ { $1=""; $2=""; sub(/^ /,""); print }')"

  local transfer_line rx tx
  transfer_line="$(printf '%s\n' "$status" | awk '/transfer:/ { $1=""; sub(/^ /,""); print }')"
  rx="$(printf '%s\n' "$transfer_line" | awk '{print $1 " " $2}')"
  tx="$(printf '%s\n' "$transfer_line" | awk '{print $4 " " $5}')"

  cat > "${STATUS_FILE}" <<EOF || true
{
  "state": "connected",
  "latest_handshake": "${latest}",
  "rx": "${rx}",
  "tx": "${tx}",
  "updated_at": "$(date -Iseconds)"
}
EOF
}

# --- Status-Loop ---
(
  while true; do
    bashio::log.info "WireGuard status:"
    wg show "${WG_INTERFACE}" || bashio::log.warning "wg show ${WG_INTERFACE} failed"
    update_status_json
    sleep 30
  done
) &

# Container am Leben halten
tail -f /dev/null
