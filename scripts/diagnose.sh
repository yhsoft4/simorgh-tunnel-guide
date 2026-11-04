#!/usr/bin/env bash
# Read-only BackPack tunnel diagnosis. Changes nothing.
# Usage: bash diagnose.sh [minutes]   (default: look back 10 minutes)
set -u
MIN="${1:-10}"

echo "== BackPack services"
systemctl list-units --no-legend 'backpack*' 2>/dev/null | awk '{print $1, $3, $4}'

echo
echo "== Recent flaps (last ${MIN} min)"
for u in $(systemctl list-units --no-legend 'backpack-*' 2>/dev/null | awk '{print $1}' | grep -vE 'monitor|webui'); do
  n=$(journalctl -u "$u" --since "-${MIN}min" --no-pager 2>/dev/null | grep -ciE 'nothing heard|restarting client|claim arrived')
  echo "$u: $n reconnect-related log lines"
done

echo
echo "== Tunnel interface (Direct mode)"
ip -br addr show 2>/dev/null | grep -E '^bp[0-9]' || echo "no bpN interface (Reverse mode, or tunnel down)"

echo
echo "== Ping through the tunnel (Direct mode)"
if ip -br addr show 2>/dev/null | grep -qE '^bp[0-9]'; then
  peer=$(ip -o addr show 2>/dev/null | awk '/ bp[0-9]/ {print $4}' | head -1 | sed 's|/.*||')
  case "$peer" in
    10.10.0.1) target=10.10.0.2 ;;
    10.10.0.2) target=10.10.0.1 ;;
    *) target="" ;;
  esac
  [ -n "$target" ] && ping -c4 -W2 "$target" | tail -2 || echo "unknown peer address"
fi

echo
echo "== Listening ports owned by backpack"
ss -ltnup 2>/dev/null | grep -i backpack | awk '{print $1, $5}' | sort -u | head -30

echo
echo "== Config summary (token hidden)"
for f in /etc/backpack/*.toml; do
  [ -f "$f" ] || continue
  echo "-- $f"
  grep -viE 'token|secret|password' "$f" | head -20
done
