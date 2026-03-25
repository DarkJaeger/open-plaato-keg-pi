<a href="https://www.buymeacoffee.com/LocutusOFB"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="41" width="174"></a>
# OpenPlaato Pi

Plug-and-play Raspberry Pi image for [open-plaato-keg](https://github.com/DarkJaeger/open-plaato-keg) — your local Plaato cloud replacement.

## Hardware

- Raspberry Pi Zero 2W,3,4,5
- microSD card (8GB+)
- Power supply

## Quick Start

1. Flash **Raspberry Pi OS Lite 64-bit** to SD card (use [Raspberry Pi Imager](https://www.raspberrypi.com/software/))
2. Boot Pi, SSH in (enable SSH via Imager advanced options)
3. Run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/DarkJaeger/open-plaato-keg-pi/main/install.sh | sudo bash
   ```
4. Reboot:
   ```bash
   sudo reboot
   ```

## First Boot Setup

1. On your phone or laptop, connect to WiFi: **OpenPlaato-Setup**
2. Open a browser and go to **192.168.4.1** (a captive portal may open automatically)
3. Enter your home WiFi network name and password, then tap **Connect**
4. The Pi reboots and joins your network — the hotspot disappears

## Finding Your Pi

- Try **http://openplaato.local** in your browser
- Or check your router's device list for the hostname **openplaato**

## Configure Your Devices

| Device | Setting |
|---|---|
| **Plaato Keg / Airlock** | Reset device → connect to its hotspot → set **Host** = Pi IP, **Port** = `1234` |
| **Web UI** | http://openplaato.local:8085 (or `http://<Pi-IP>:8085`) |
| **iOS / Android app** | Set server URL to `http://openplaato.local:8085` |

## Updates

[Watchtower](https://containrrr.dev/watchtower/) automatically checks for and pulls updates to the `open-plaato-keg` container once per day.

## How It Works

```
First boot
  └─ openplaato-setup.service (systemd)
       └─ setup.sh
            ├─ No flag file? → start hotspot (hostapd + dnsmasq)
            │                   → serve captive portal (connect.py)
            │                   → on WiFi submit → write wpa_supplicant.conf
            │                                    → write flag file → reboot
            └─ Flag file exists? → docker compose up -d
```

## Project Structure

```
.
├── docker-compose.yml          # open-plaato-keg + watchtower
├── install.sh                  # One-time setup script (run on fresh Pi OS)
├── setup.sh                    # First-boot logic (hotspot or docker)
├── openplaato-setup.service    # systemd unit
├── hostapd.conf                # Access point config
├── dnsmasq.conf                # DHCP + DNS for captive portal
└── captive-portal/
    ├── index.html              # WiFi setup UI
    └── connect.py              # HTTP server handling WiFi credentials
```
