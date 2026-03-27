#!/bin/bash
set -e

FLAG_FILE_PRIMARY="/boot/firmware/openplaato-configured"
FLAG_FILE_FALLBACK="/boot/openplaato-configured"
INSTALL_DIR="/opt/openplaato"

# Determine which flag file path to use
if [ -d "/boot/firmware" ]; then
    FLAG_FILE="$FLAG_FILE_PRIMARY"
else
    FLAG_FILE="$FLAG_FILE_FALLBACK"
fi

if [ -f "$FLAG_FILE" ]; then
    echo "OpenPlaato already configured — starting services..."
    cd "$INSTALL_DIR"
    docker compose up -d
    exit 0
fi

echo "First boot detected — starting hotspot setup mode..."

# Stop anything that might hold wlan0
systemctl stop wpa_supplicant 2>/dev/null || true
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true
killall wpa_supplicant 2>/dev/null || true
sleep 2

# Unblock wifi radio (required on Pi 4 — rfkill blocks wlan0 by default)
rfkill unblock wifi
sleep 1

# Assign static IP to wlan0
ip addr flush dev wlan0
ip addr add 192.168.4.1/24 dev wlan0
ip link set wlan0 up

# Start hostapd
systemctl start hostapd

# Bounce wlan0 to ensure hostapd takes AP mode
ip link set wlan0 down
ip link set wlan0 up
systemctl restart hostapd

# Start dnsmasq
systemctl start dnsmasq

echo "Hotspot active — SSID: OpenPlaato-Setup"

# Start captive portal HTTP server
cd "$INSTALL_DIR/captive-portal"
python3 connect.py
