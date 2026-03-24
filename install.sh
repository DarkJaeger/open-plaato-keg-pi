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
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
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

echo ""
echo "✅ OpenPlaato installed! Reboot to start setup: sudo reboot"
