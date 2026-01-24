#!/usr/bin/with-contenv bashio
# Einfacher WireGuard-Client für Home Assistant

set -e

CONFIG_FILE=$(bashio::config 'config_file')
ENABLED=$(bashio::config 'enabled')

if [ "$ENABLED" != "true" ]; then
  bashio::log.info "WireGuard client disabled (enabled=false). Exiting."
  exit 0
fi

if [ ! -f "$CONFIG_FILE" ]; then
  bashio::log.error "Config file $CONFIG_FILE not found."
  exit 1
fi

bashio::log.info "Starting WireGuard with config: ${CONFIG_FILE}"

# WireGuard-Interface starten
wg-quick up "$CONFIG_FILE"

bashio::log.info "WireGuard client started. Keeping container alive."
tail -f /dev/null
