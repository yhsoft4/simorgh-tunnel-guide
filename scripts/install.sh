#!/usr/bin/env bash
# Downloads and runs the OFFICIAL, unmodified BackPack installer, then prints
# the next steps. Run as root. Read the installer first if you wish:
#   https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }

URL="https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL --connect-timeout 15 "$URL" -o "$tmp"
echo "Downloaded official installer ($(wc -l < "$tmp") lines). Running it..."
bash "$tmp" </dev/null

cat <<'EOF'

Installed. Next steps:
  1. Run the Connection Test on both servers:  sudo backpack  ->  0
       Iran side: 1 (Iran) and copy the link
       Kharej side: 2 (Kharej) and paste it
  2. Read "Works Steadily" and create the tunnel with that transport.
  3. Verify with:  bash scripts/diagnose.sh

Based on BackPack by Amin Mohammadi (AminMGMT)
https://github.com/AminMGMT/BackPack
EOF
