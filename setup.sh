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

# Stop and MASK anything that might interfere (mask prevents socket-triggered respawn)
systemctl stop wpa_supplicant 2>/dev/null || true
systemctl disable wpa_supplicant 2>/dev/null || true
systemctl mask wpa_supplicant 2>/dev/null || true
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true
systemctl mask NetworkManager 2>/dev/null || true
killall wpa_supplicant 2>/dev/null || true
# Stop avahi — must stop socket first or service respawns via socket activation
systemctl stop avahi-daemon.socket 2>/dev/null || true
systemctl stop avahi-daemon 2>/dev/null || true
systemctl mask avahi-daemon.socket 2>/dev/null || true
systemctl mask avahi-daemon 2>/dev/null || true
sleep 2

# Unblock wifi radio (required on Pi 4 — rfkill blocks wlan0 by default)
rfkill unblock wifi
sleep 1

# Bring wlan0 up clean before hostapd
ip addr flush dev wlan0
ip link set wlan0 up

# Start hostapd — it takes ownership of wlan0 in AP mode
systemctl start hostapd
sleep 2

# Assign static IP AFTER hostapd is up (hostapd resets the interface)
ip addr flush dev wlan0
ip addr add 192.168.4.1/24 dev wlan0
ip link set wlan0 up

# Start dnsmasq
systemctl start dnsmasq

echo "Hotspot active — SSID: OpenPlaato-Setup"

# Start captive portal HTTP server
cd "$INSTALL_DIR/captive-portal"
python3 connect.py
