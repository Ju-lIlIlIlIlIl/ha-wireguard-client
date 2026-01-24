# WireGuard Client Home Assistant Add-on

![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)
![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports armv7](https://img.shields.io/badge/armv7-yes-green.svg)
![Supports armhf](https://img.shields.io/badge/armhf-yes-green.svg)

A simple **WireGuard client add-on for Home Assistant**.  
This add-on allows Home Assistant to **connect as a WireGuard client** to an existing WireGuard server (e.g. wg-easy, Fritz!Box, VPS).

---

## ✨ Features

- 🔐 Home Assistant acts as **WireGuard client**
- 📄 Upload or paste a full `wg.conf`
- 🚀 Automatic tunnel start on add-on startup
- ♻️ Reconnects after reboot
- 🧠 Designed for **remote maintenance & customer setups**
- 🧩 No Proxmox, no router VPN required

---

## 📦 Installation

### 1️⃣ Add the repository to Home Assistant

Click the button below:

[![Add Add-on Repository to Home Assistant](https://my.home-assistant.io/badges/addon_repository.svg)](
https://my.home-assistant.io/redirect/supervisor_addon/?repository_url=https://github.com/Ju-lIlIlIlIlIl/ha-wireguard-client-addon
)

Or manually:

1. Go to **Settings → Add-ons → Add-on Store**
2. Click the **three dots (⋮)** in the top right
3. Select **Repositories**
4. Add this URL:
https://github.com/Ju-lIlIlIlIlIl/ha-wireguard-client-addon


---

### 2️⃣ Install the Add-on

1. Find **WireGuard Client** in the Add-on Store
2. Click **Install**
3. Wait until installation is finished

---

## ⚙️ Configuration

This add-on requires a **complete WireGuard client configuration** (`wg.conf`).

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
```
Add-on Options
Paste the entire configuration into the add-on option:

wg_config: |
  [Interface]
  PrivateKey = ...
  Address = ...
  
  [Peer]
  PublicKey = ...
  Endpoint = ...
Save the configuration.

▶️ Start the Add-on
Click Start

Open the Logs

You should see:

[INFO] WireGuard up
If successful, Home Assistant is now connected to your WireGuard server.

🔎 Verification
From your WireGuard server, you should see the HA peer connected:

wg show
You should now be able to:

Access Home Assistant remotely

Reach HA local IPs via VPN

Perform maintenance without router VPNs

🔁 Updates
When a new version is released:

Open the Add-on page

Click Update

Restart the add-on

⚠️ Notes
This add-on runs WireGuard as client only

Routing depends on AllowedIPs

Make sure IP ranges do not overlap with the remote network

Requires WireGuard support in the HA OS (already included in HA OS)

🛠 Roadmap
Planned features:

📂 Upload .conf file via UI

📊 Connection status sensor

🔄 Auto-reconnect watchdog

🔔 HA notifications on disconnect

🧑‍💼 Multi-customer profiles

💬 Support & Development
GitHub Repository:
👉 https://github.com/Ju-lIlIlIlIlIl/ha-wireguard-client-addon

Issues & feature requests welcome.

🧠 Why this Add-on?
Most WireGuard solutions for Home Assistant assume HA is the server.
This add-on solves the real-world problem of making HA a managed VPN client for:

customer installations

MSP / integrator workflows

remote diagnostics

secure access without touching customer routers

License: MIT
Status: Experimental
