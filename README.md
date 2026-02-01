# WireGuard Client Home Assistant Add-on

![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)
![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports armv7](https://img.shields.io/badge/armv7-yes-green.svg)
![Supports armhf](https://img.shields.io/badge/armhf-yes-green.svg)

A simple **WireGuard client add-on for Home Assistant**.  
This add-on allows Home Assistant to **connect as a WireGuard client** to an existing WireGuard server  
(e.g. wg-easy, Fritz!Box, VPS).

---

## ✨ Features

- 🔐 Home Assistant acts as **WireGuard client**
- 📄 Paste a full `wg.conf` directly into the add-on configuration
- 👁 Private keys are **hidden** in the UI (password field with visibility toggle)
- 🚀 Automatic tunnel start on add-on startup
- ♻️ Reconnects after reboot
- 📊 Detailed **connection status in logs** (handshake, traffic, endpoint)
- 🧠 Designed for **remote maintenance & customer setups**
- 🧩 No Proxmox, no router VPN required

---

## 📦 Installation

### 1️⃣ Add the repository to Home Assistant

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](
https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FJu-lIlIlIlIlIl%2Fha-wireguard-client
)

Or manually:

1. Go to **Settings → Add-ons → Add-on Store**
2. Click the **three dots (⋮)** in the top right
3. Select **Repositories**
4. Add:
https://github.com/Ju-lIlIlIlIlIl/ha-wireguard-client


---

## ⚙️ Configuration

This add-on requires a **WireGuard client configuration**.

### Example `wg.conf`

```ini
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.10.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
PresharedKey = <PRESHARED_KEY>
Endpoint = your-server.example.com:51820
AllowedIPs = 10.10.0.0/24, 192.168.178.0/24
PersistentKeepalive = 25
Add-on Options
Paste the entire configuration into the add-on option:

wg_config: |
  [Interface]
  PrivateKey = ...
  Address = ...

  [Peer]
  PublicKey = ...
  Endpoint = ...
Then Save and Start the add-on.

📊 Connection Status & Logs
The add-on continuously logs the WireGuard status.

Example log output:

[INFO] WireGuard status:
peer: SpMSY1vwHVVeodmmuVM8p8XYOd/SRkxqTsongkfUBEY=
  endpoint: 158.180.23.24:51820
  latest handshake: 10 seconds ago
  transfer: 715.79 KiB received, 7.49 MiB sent
How to interpret this:
latest handshake → last successful connection to the server

If the handshake updates regularly → connection is active

No handshake → tunnel is down

➡️ Logs are the authoritative source of truth for WireGuard state.

🔎 Verification
From the WireGuard server:

wg show
You should see the Home Assistant peer connected.

You can now:

Access Home Assistant remotely

Reach HA services via VPN IP

Perform maintenance without router VPNs

🔁 Updates
When a new version is released:

Open the add-on page

Click Update

Restart the add-on

⚠️ Notes
This add-on runs WireGuard client only

Routing depends on AllowedIPs

Make sure VPN IP ranges do not overlap

WireGuard kernel support is already included in HA OS

🛠 Roadmap
Planned / possible improvements:

📊 WireGuard status sensors inside Home Assistant

🔔 Notifications on disconnect

🔄 Connection watchdog

📂 File upload for .conf (UI limitation dependent)

🧑‍💼 Why this Add-on?
Most WireGuard solutions assume Home Assistant is the server.

This add-on solves the real-world problem of making Home Assistant a managed VPN client for:

customer installations

MSP / integrator workflows

remote diagnostics

secure access without touching customer routers

License: MIT
Status: Experimental
