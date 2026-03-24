#!/usr/bin/env python3
"""Captive portal HTTP server for OpenPlaato first-boot WiFi setup."""

import json
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

PORTAL_DIR = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE_PRIMARY = "/boot/firmware/openplaato-configured"
FLAG_FILE_FALLBACK = "/boot/openplaato-configured"

WPA_SUPPLICANT_PATH = "/etc/wpa_supplicant/wpa_supplicant.conf"


def flag_file_path():
    if os.path.isdir("/boot/firmware"):
        return FLAG_FILE_PRIMARY
    return FLAG_FILE_FALLBACK


def write_wpa_supplicant(ssid: str, password: str) -> None:
    if password:
        network_block = (
            'network={{\n'
            '    ssid="{ssid}"\n'
            '    psk="{password}"\n'
            '    key_mgmt=WPA-PSK\n'
            '}}\n'
        ).format(ssid=ssid, password=password)
    else:
        network_block = (
            'network={{\n'
            '    ssid="{ssid}"\n'
            '    key_mgmt=NONE\n'
            '}}\n'
        ).format(ssid=ssid)

    content = (
        'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n'
        'update_config=1\n'
        'country=US\n'
        '\n'
        + network_block
    )

    with open(WPA_SUPPLICANT_PATH, "w") as f:
        f.write(content)


def connect_and_reboot(ssid: str, password: str) -> None:
    write_wpa_supplicant(ssid, password)

    # Stop hotspot services
    subprocess.run(["systemctl", "stop", "hostapd"], check=False)
    subprocess.run(["systemctl", "stop", "dnsmasq"], check=False)

    # Reconfigure wlan0
    subprocess.run(["ip", "addr", "flush", "dev", "wlan0"], check=False)
    subprocess.run(["wpa_supplicant", "-B", "-i", "wlan0",
                    "-c", WPA_SUPPLICANT_PATH], check=False)
    subprocess.run(["dhclient", "wlan0"], check=False)

    # Write configured flag
    flag = flag_file_path()
    with open(flag, "w") as f:
        f.write("configured\n")

    # Reboot
    subprocess.Popen(["reboot"])


class PortalHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # suppress default access log noise
        print(f"[portal] {self.address_string()} - {fmt % args}", flush=True)

    def send_json(self, data: dict, status: int = 200) -> None:
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            index_path = os.path.join(PORTAL_DIR, "index.html")
            with open(index_path, "rb") as f:
                body = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            # Redirect everything else to the portal (captive portal behaviour)
            self.send_response(302)
            self.send_header("Location", "/")
            self.end_headers()

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path != "/connect":
            self.send_json({"success": False, "error": "not found"}, 404)
            return

        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length).decode("utf-8", errors="replace")
        params = parse_qs(raw_body)

        ssid_list = params.get("ssid", [])
        password_list = params.get("password", [])

        if not ssid_list:
            self.send_json({"success": False, "error": "ssid required"}, 400)
            return

        ssid = ssid_list[0].strip()
        password = password_list[0] if password_list else ""

        # Respond before rebooting so the browser receives the JSON
        self.send_json({"success": True})

        # Run connection + reboot in a subprocess so response is flushed first
        import threading
        t = threading.Thread(target=connect_and_reboot, args=(ssid, password), daemon=True)
        t.start()


def main() -> None:
    server_address = ("0.0.0.0", 80)
    httpd = HTTPServer(server_address, PortalHandler)
    print("[portal] Listening on http://0.0.0.0:80", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("[portal] Shutting down.", flush=True)
        sys.exit(0)


if __name__ == "__main__":
    main()
