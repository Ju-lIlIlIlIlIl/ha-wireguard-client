#!/usr/bin/with-contenv bashio
set -e

WG_CONF="/etc/wireguard/client.conf"
WG_CONF_WG="/etc/wireguard/client.wg"
WG_INTERFACE="client"

bashio::log.info "Starting WireGuard Client add-on"

# --- Optionen aus /data/options.json lesen ---
PRIVATE_KEY=$(bashio::config 'private_key')
ADDRESS=$(bashio::config 'address')
DNS=$(bashio::config 'dns')
PUBLIC_KEY=$(bashio::config 'public_key')
PRESHARED_KEY=$(bashio::config 'preshared_key')
ENDPOINT=$(bashio::config 'endpoint')
ALLOWED_IPS=$(bashio::config 'allowed_ips')

# --- Pflichtfelder prüfen ---
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "null" ]; then
  bashio::log.error "private_key is empty or null – please configure the add-on!"
  exit 1
fi

if [ -z "$ADDRESS" ] || [ "$ADDRESS" = "null" ]; then
  bashio::log.error "address is empty or null – please configure the add-on!"
  exit 1
fi

if [ -z "$PUBLIC_KEY" ] || [ "$PUBLIC_KEY" = "null" ]; then
  bashio::log.error "public_key is empty or null – please configure the add-on!"
  exit 1
fi

if [ -z "$ENDPOINT" ] || [ "$ENDPOINT" = "null" ]; then
  bashio::log.error "endpoint is empty or null – please configure the add-on!"
  exit 1
fi

# Default für AllowedIPs
if [ -z "$ALLOWED_IPS" ] || [ "$ALLOWED_IPS" = "null" ]; then
  ALLOWED_IPS="0.0.0.0/0,::/0"
fi

bashio::log.info "Generating WireGuard config at ${WG_CONF}"

# --- Volle Config (wg-quick-Style) für Logging / Debug ---
cat > "${WG_CONF}" <<EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${ADDRESS}
EOF

# DNS nur, wenn gesetzt (nur für Debug-Ausgabe, nicht für wg setconf)
if [ -n "${DNS}" ] && [ "${DNS}" != "null" ]; then
  echo "DNS = ${DNS}" >> "${WG_CONF}"
fi

cat >> "${WG_CONF}" <<EOF

[Peer]
PublicKey = ${PUBLIC_KEY}
AllowedIPs = ${ALLOWED_IPS}
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF

# PresharedKey nur, wenn gesetzt
if [ -n "${PRESHARED_KEY}" ] && [ "${PRESHARED_KEY}" != "null" ]; then
  sed -i "/\[Peer\]/a PresharedKey = ${PRESHARED_KEY}" "${WG_CONF}"
fi

bashio::log.info "Resulting WireGuard config (for debugging):"
sed 's/PrivateKey = .*/PrivateKey = ****/; s/PresharedKey = .*/PresharedKey = ****/' "${WG_CONF}"

# --- Gestripte Config NUR für wg setconf (ohne Address/DNS) ---
cat > "${WG_CONF_WG}" <<EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}

[Peer]
PublicKey = ${PUBLIC_KEY}
AllowedIPs = ${ALLOWED_IPS}
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF

if [ -n "${PRESHARED_KEY}" ] && [ "${PRESHARED_KEY}" != "null" ]; then
  sed -i "/\[Peer\]/a PresharedKey = ${PRESHARED_KEY}" "${WG_CONF_WG}"
fi

bashio::log.info "Bringing up WireGuard interface: ${WG_INTERFACE}"

# Falls Interface noch existiert → wegräumen
if ip link show "${WG_INTERFACE}" >/dev/null 2>&1; then
  bashio::log.warning "Interface '${WG_INTERFACE}' already exists – deleting it first"
  ip link delete dev "${WG_INTERFACE}" || true
fi

# Interface anlegen & Konfig anwenden
ip link add dev "${WG_INTERFACE}" type wireguard
wg setconf "${WG_INTERFACE}" "${WG_CONF_WG}"

# IP-Adresse setzen (das ist der Teil, den wg-quick sonst machen würde)
ip -4 address add "${ADDRESS}" dev "${WG_INTERFACE}"
ip link set mtu 1420 up dev "${WG_INTERFACE}"

bashio::log.info "WireGuard interface '${WG_INTERFACE}' is up"

# --- Einfacher Status-Loop: nur ins Log schreiben, KEINE Dateien/Sensoren ---
bashio::log.info "[INFO] Starting WireGuard status monitor (log only, every 30s) ..."
while true; do
  bashio::log.info "WireGuard status:"
  if ! wg show "${WG_INTERFACE}"; then
    bashio::log.warning "wg show ${WG_INTERFACE} failed"
  fi
  sleep 30
done
