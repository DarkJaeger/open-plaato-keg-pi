# OpenPlaato Pi Server — Installation Guide

This guide walks you through flashing the OpenPlaato server image to an SD card and connecting it to your home network.

---

## What You'll Need

- Raspberry Pi (Pi 3, 4, or Zero 2W recommended)
- MicroSD card (16GB minimum, 32GB recommended)
- Power supply for your Pi
- A Windows, Mac, or Linux computer
- [Balena Etcher](https://etcher.balena.io/) installed on your computer
- The OpenPlaato Pi image file (`.img.xz`)

---

## Step 1: Download and Install Balena Etcher

1. Go to [https://etcher.balena.io](https://etcher.balena.io)
2. Download the version for your operating system
3. Install and open it

---

## Step 2: Flash the Image to Your SD Card

1. Insert your MicroSD card into your computer (using a card reader if needed)
2. Open Balena Etcher
3. Click **"Flash from file"** and select the `open-plaato-pi-server.img.xz` file
   - Etcher handles `.xz` compressed images directly — no need to decompress first
4. Click **"Select target"** and choose your MicroSD card
   - ⚠️ **Double-check you have the right drive selected** — this will erase everything on it
5. Click **"Flash!"** and wait for it to complete (5–10 minutes)
6. Once done, eject the SD card safely

---

## Step 3: First Boot — Connect to the Setup Network

1. Insert the MicroSD card into your Raspberry Pi
2. Power on the Pi
3. Wait about 60 seconds for it to boot
4. On your phone or computer, open your WiFi settings
5. Connect to the network: **`OpenPlaato-Setup`** (no password required)

---

## Step 4: Configure Your WiFi

1. After connecting to `OpenPlaato-Setup`, open a web browser
2. The setup page should appear automatically (captive portal)
   - If it doesn't open automatically, go to: **http://192.168.4.1**
3. Enter your home WiFi network name (SSID) and password
4. Click **"Connect"**
5. The Pi will reboot automatically and connect to your WiFi network

---

## Step 5: Access the OpenPlaato Server

1. Wait about 60 seconds after the reboot
2. On a device connected to your home WiFi, open a browser and go to:
   **[http://openplaato.local:8085](http://openplaato.local:8085)**
3. The OpenPlaato web interface should load

> **Tip:** If `openplaato.local` doesn't resolve, check your router's connected devices list to find the Pi's IP address and use that instead (e.g. `http://192.168.1.xxx:8085`)

---

## Pointing Your Plaato Devices to the Server

Once the server is running, configure your Plaato Keg devices to send data to:
- **Host:** `openplaato.local` (or the Pi's IP address)
- **Port:** `1234`

---

## Troubleshooting

**The `OpenPlaato-Setup` network doesn't appear**
- Wait a full 60 seconds after powering on
- Make sure the SD card is fully seated
- Try power cycling the Pi

**Setup page doesn't load after connecting to the AP**
- Manually navigate to `http://192.168.4.1` in your browser
- Disable mobile data on your phone (it may route around the captive portal)

**`openplaato.local` doesn't resolve after setup**
- Wait a bit longer — the Pi may still be booting
- Try finding the Pi's IP in your router's device list
- Windows users: make sure Bonjour is installed (comes with iTunes/Apple devices)

**Need to reset and reconfigure WiFi**
- SSH into the Pi: `ssh openplaato@openplaato.local` (password: `openplaatoserver`)
- Run: `sudo /opt/openplaato/reset.sh`
- The Pi will reboot into AP setup mode

---

## Notes

- Default SSH credentials: `openplaato` / `openplaatoserver`
- Change your password after setup: `passwd`
- The server runs in Docker and starts automatically on boot
- Pi 4 users: you can also connect via ethernet (eth0) for the main network — the setup AP runs on WiFi (wlan0) regardless
