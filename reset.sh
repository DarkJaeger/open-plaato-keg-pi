#!/bin/bash
# OpenPlaato Reset Script
# Removes the configured flag and saved WiFi connection, then reboots into AP setup mode.

set -e

FLAG_FILE_PRIMARY="/boot/firmware/openplaato-configured"
FLAG_FILE_FALLBACK="/boot/openplaato-configured"

echo "==> Resetting OpenPlaato to factory setup mode..."

# Remove configured flag
if [ -f "$FLAG_FILE_PRIMARY" ]; then
    rm -f "$FLAG_FILE_PRIMARY"
    echo "Removed $FLAG_FILE_PRIMARY"
elif [ -f "$FLAG_FILE_FALLBACK" ]; then
    rm -f "$FLAG_FILE_FALLBACK"
    echo "Removed $FLAG_FILE_FALLBACK"
else
    echo "No configured flag found — already in factory state."
fi

# Remove saved WiFi connections (skip loopback and ethernet)
echo "==> Removing saved WiFi connections..."
nmcli -t -f NAME,TYPE connection show | grep wifi | cut -d: -f1 | while read -r conn; do
    echo "Deleting connection: $conn"
    nmcli connection delete "$conn" 2>/dev/null || true
done

echo ""
echo "✅ Reset complete. Rebooting into AP setup mode..."
sleep 2
reboot
