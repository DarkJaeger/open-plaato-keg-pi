#!/bin/bash
set -e

INSTALL_DIR="/opt/openplaato"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing base dependencies..."
apt-get update -y
apt-get install -y \
    hostapd \
    dnsmasq \
    avahi-daemon \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

echo "==> Installing Docker (official)..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
# Use bookworm — Docker doesn't have trixie builds yet, bookworm packages work fine
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "==> Enabling core services..."
systemctl enable docker
systemctl enable avahi-daemon

echo "==> Setting hostname to 'openplaato'..."
hostnamectl set-hostname openplaato

# Update /etc/hosts so the new hostname resolves locally
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1\s.*/127.0.1.1\topenplaato/" /etc/hosts
else
    echo "127.0.1.1	openplaato" >> /etc/hosts
fi

echo "==> Configuring Avahi mDNS..."
sed -i "s/^#*host-name=.*/host-name=openplaato/" /etc/avahi/avahi-daemon.conf

echo "==> Creating install directory..."
mkdir -p "$INSTALL_DIR/db"

echo "==> Copying application files..."
cp "$SCRIPT_DIR/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml"
cp "$SCRIPT_DIR/setup.sh" "$INSTALL_DIR/setup.sh"
chmod +x "$INSTALL_DIR/setup.sh"

cp -r "$SCRIPT_DIR/captive-portal" "$INSTALL_DIR/captive-portal"

echo "==> Installing hostapd config..."
cp "$SCRIPT_DIR/hostapd.conf" /etc/hostapd/hostapd.conf

# Point hostapd at our config
if grep -q "^DAEMON_CONF=" /etc/default/hostapd 2>/dev/null; then
    sed -i 's|^DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
else
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
fi

echo "==> Installing dnsmasq config..."
cp "$SCRIPT_DIR/dnsmasq.conf" /etc/dnsmasq.d/openplaato.conf

echo "==> Installing systemd service..."
cp "$SCRIPT_DIR/openplaato-setup.service" /etc/systemd/system/openplaato-setup.service
systemctl daemon-reload
systemctl enable openplaato-setup

# Mark as already configured (WiFi already set up by user)
if [ -d "/boot/firmware" ]; then
    touch /boot/firmware/openplaato-configured
else
    touch /boot/openplaato-configured
fi

echo ""
echo "✅ OpenPlaato installed!"
echo ""
echo "Reboot to start: sudo reboot"
echo "After reboot, access the web UI at: http://openplaato.local:8085"
echo "Point your Plaato devices to: $(hostname -I | awk '{print $1}') port 1234"
