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
killall wpa_supplicant 2>/dev/null || true

# Give it a moment to release the interface
sleep 2

# Bring wlan0 up clean with static IP
ip link set wlan0 down
ip addr flush dev wlan0
ip link set wlan0 up
ip addr add 192.168.4.1/24 dev wlan0

# Start hostapd
systemctl start hostapd

# Give hostapd a moment to start
sleep 2

# Start dnsmasq
systemctl start dnsmasq

echo "Hotspot active — SSID: OpenPlaato-Setup"

# Start captive portal HTTP server
cd "$INSTALL_DIR/captive-portal"
python3 connect.py
