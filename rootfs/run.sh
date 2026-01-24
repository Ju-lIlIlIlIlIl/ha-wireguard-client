#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting WireGuard Client add-on"

ENABLED=$(bashio::config 'enabled')
if ! bashio::var.true "${ENABLED}"; then
    bashio::log.info "Add-on is disabled via configuration. Exiting."
    exit 0
fi

CONFIG_FILE=$(bashio::config 'config_file')
CONFIG_CONTENT=$(bashio::config 'config_content')

# Wenn config_content gesetzt ist, daraus eine Datei bauen
if [ -n "${CONFIG_CONTENT}" ]; then
    bashio::log.info "config_content found – writing WireGuard config to /etc/wireguard/client.conf"
    mkdir -p /etc/wireguard
    # Wichtig: Inhalt 1:1 übernehmen
    printf "%s\n" "${CONFIG_CONTENT}" > /etc/wireguard/client.conf
    CONFIG_FILE="/etc/wireguard/client.conf"
fi

if [ -z "${CONFIG_FILE}" ]; then
    bashio::log.error "No config_file or config_content configured. Please set one of them in the add-on options."
    exit 1
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    bashio::log.error "Config file '${CONFIG_FILE}' not found."
    exit 1
fi

bashio::log.info "Bringing up WireGuard using config: ${CONFIG_FILE}"
wg-quick up "${CONFIG_FILE}"

finish() {
    bashio::log.info "Stopping WireGuard"
    wg-quick down "${CONFIG_FILE}" || true
    exit 0
}

trap finish SIGTERM SIGHUP

# Add-on am Leben halten
while true; do
    sleep 60
done
