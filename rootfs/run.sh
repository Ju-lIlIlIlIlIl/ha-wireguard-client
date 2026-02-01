#!/usr/bin/with-contenv bashio
set -e

WG_INTERFACE="client"
WG_CONF="/etc/wireguard/client.conf"        # Vollständige Config zur Kontrolle/Debug
WG_RUNTIME_CONF="/tmp/wg_client_runtime.conf"  # Minimal-Config nur für wg setconf
STATUS_FILE="/config/wireguard_client_status.json"

bashio::log.info "Starting WireGuard Client add-on"

# --- Optionen aus /data/options.json lesen ---
PRIVATE_KEY=$(bashio::config 'private_key')
ADDRESS=$(bashio::config 'address')
DNS=$(bashio::config 'dns')
PUBLIC_KEY=$(bashio::config 'public_key')
PRESHARED_KEY=$(bashio::config 'preshared_key')
ENDPOINT=$(bashio::config 'endpoint')
ALLOWED_IPS=$(bashio::config 'allowed_ips')
PERSISTENT_KEEPALIVE=$(bashio::config 'persistent_keepalive')

# --- Konfig prüfen ---
if [ -z "${PRIVATE_KEY}" ] || [ -z "${ADDRESS}" ] || [ -z "${PUBLIC_KEY}" ] || [ -z "${ENDPOINT}" ]; then
  bashio::log.fatal "private_key, address, public_key und endpoint müssen gesetzt sein!"
  exit 1
fi

if [ -z "${ALLOWED_IPS}" ]; then
  bashio::log.warning "allowed_ips ist leer – Standard 0.0.0.0/0 wird verwendet."
  ALLOWED_IPS="0.0.0.0/0"
fi

if [ -z "${PERSISTENT_KEEPALIVE}" ] || [ "${PERSISTENT_KEEPALIVE}" = "null" ]; then
  PERSISTENT_KEEPALIVE="25"
fi

# --- Vollständige WireGuard-Konfiguration (Debug) schreiben ---
bashio::log.info "Generating WireGuard config at ${WG_CONF}"

{
  echo "[Interface]"
  echo "PrivateKey = ${PRIVATE_KEY}"
  echo "Address = ${ADDRESS}"
  if [ -n "${DNS}" ]; then
    echo "DNS = ${DNS}"
  fi
  echo ""
  echo "[Peer]"
  if [ -n "${PRESHARED_KEY}" ]; then
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

# --- Interface vorbereiten (vorherige Reste aufräumen) ---
if ip link show "${WG_INTERFACE}" >/dev/null 2>&1; then
  bashio::log.warning "Interface '${WG_INTERFACE}' already exists – deleting it first"
  ip link delete dev "${WG_INTERFACE}" || true
fi

# --- WireGuard-Interface anlegen ---
bashio::log.info "Creating WireGuard interface: ${WG_INTERFACE}"
if ! ip link add dev "${WG_INTERFACE}" type wireguard; then
  bashio::log.fatal "Failed to create WireGuard interface '${WG_INTERFACE}'"
  exit 1
fi

# --- Minimal-Config für wg setconf schreiben (ohne Address/DNS) ---
{
  echo "[Interface]"
  echo "PrivateKey = ${PRIVATE_KEY}"
  echo ""
  echo "[Peer]"
  echo "PublicKey = ${PUBLIC_KEY}"
  if [ -n "${PRESHARED_KEY}" ]; then
    echo "PresharedKey = ${PRESHARED_KEY}"
  fi
  echo "AllowedIPs = ${ALLOWED_IPS}"
  echo "Endpoint = ${ENDPOINT}"
  echo "PersistentKeepalive = ${PERSISTENT_KEEPALIVE}"
} > "${WG_RUNTIME_CONF}"

# --- Konfiguration auf das Interface anwenden ---
bashio::log.info "Applying WireGuard configuration using wg setconf"
if ! wg setconf "${WG_INTERFACE}" "${WG_RUNTIME_CONF}"; then
  bashio::log.fatal "Failed to apply WireGuard configuration with wg setconf"
  ip link delete dev "${WG_INTERFACE}" || true
  exit 1
fi

# --- IPv4-Adresse setzen & Interface hochfahren ---
bashio::log.info "Configuring IP address ${ADDRESS} on ${WG_INTERFACE}"
if ! ip -4 address add "${ADDRESS}" dev "${WG_INTERFACE}" 2>/dev/null; then
  bashio::log.warning "Could not set IPv4 address ${ADDRESS} on interface ${WG_INTERFACE}"
fi

# MTU & Interface hoch
if ! ip link set mtu 1420 up dev "${WG_INTERFACE}"; then
  bashio::log.warning "Failed to set MTU or bring interface up"
fi

bashio::log.info "WireGuard interface '${WG_INTERFACE}' is up"

# --- Status-Datei vorbereiten ---
mkdir -p /config
if [ ! -f "${STATUS_FILE}" ]; then
  echo '{"state":"starting","latest_handshake":null,"rx":null,"tx":null,"updated_at":null}' > "${STATUS_FILE}" || true
fi

# --- Funktion: Status in JSON-Datei schreiben ---
update_status_json() {
  # wg show darf das Script nicht killen, daher Exit-Code ignorieren
  local status
  status="$(wg show "${WG_INTERFACE}" 2>/dev/null || true)"

  if [ -z "${status}" ]; then
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

  # latest handshake Zeile extrahieren
  local latest
  latest="$(printf '%s\n' "${status}" | awk '/latest handshake:/ { $1=""; $2=""; sub(/^ /,""); print }')"

  # transfer Zeile extrahieren
  local transfer_line rx tx
  transfer_line="$(printf '%s\n' "${status}" | awk '/transfer:/ { $1=""; sub(/^ /,""); print }')"
  # Form: "715.79 KiB received, 7.49 MiB sent"
  rx="$(printf '%s\n' "${transfer_line}" | awk '{print $1 " " $2}')"
  tx="$(printf '%s\n' "${transfer_line}" | awk '{print $4 " " $5}')"

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

# --- Status-Loop: alle 30s Status loggen & JSON aktualisieren ---
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
