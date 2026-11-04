# Simorgh Tunnel Guide

**English** · [فارسی](README_FA.md)

A field-tested guide and a small set of helper scripts for running a
[BackPack](https://github.com/AminMGMT/BackPack) tunnel between two VPS servers
(an *Iran-side* entry server and a *kharej* server abroad), and for recovering
when the tunnel keeps flapping.

> Based on BackPack by Amin Mohammadi (AminMGMT)
> https://github.com/AminMGMT/BackPack

This repository does **not** contain or modify BackPack. It uses the official,
unmodified BackPack release and only adds documentation and shell scripts.
BackPack itself is licensed under AGPL-3.0 and its name belongs to its author.

---

## What this is about

We had a tunnel that worked for weeks and then started dropping every ~17
seconds. Users kept disconnecting. This repo records the full diagnosis and the
fix that worked, so you can repeat it in about 20 minutes.

**Symptom (client log):**

```
[WARNING] nothing heard from the server for 15s after it had been heartbeating
[INFO] restarting client...
```

**Root cause (in our case):** the *Reverse TCP* transport was unstable on that
network path. Ping, SSH and raw port checks were all fine, which is why it was
confusing. BackPack's built-in **Connection Test** (menu option `0`) showed it
clearly: TCP 85 %, WS 77 %, while PCK was 60/60.

**Fix:** move from a *Reverse TCP* tunnel to a **Direct PCK** layer-3 tunnel
with the same forwarded ports. Zero flaps afterwards, 0 % packet loss, ~78 ms.

Full story: [docs/case-study.md](docs/case-study.md)
Step-by-step: [docs/howto.md](docs/howto.md)

---

## Quick start

1. Install BackPack on **both** servers (official installer, as root):

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh)
   ```

   or use our wrapper, which downloads the same official installer and prints
   the next steps:

   ```bash
   bash scripts/install.sh
   ```

2. Find out which transport your path really supports.
   On the Iran side run `sudo backpack` → `0` → `1` (Iran), copy the link;
   on the kharej side `sudo backpack` → `0` → `2` (Kharej) and paste it.
   Wait ~4 minutes and read **Works Steadily**.

3. Create the tunnel with the best transport (Setup Iran → Direct → PCK, list
   the ports you want forwarded, then apply the link it prints on the kharej
   server).

4. Verify:

   ```bash
   bash scripts/diagnose.sh          # read-only, safe to run any time
   ```

---

## Scripts

| Script | What it does | Changes anything? |
|---|---|---|
| `scripts/install.sh` | Downloads and runs the official BackPack installer, then prints next steps | Installs BackPack |
| `scripts/diagnose.sh` | Lists tunnel services, counts recent flaps, checks interface, ping through the tunnel, and listening ports | No (read-only) |
| `scripts/check-ports.sh HOST PORT...` | Tests that TCP ports on a server accept connections | No |
| `scripts/monitor.sh IRAN_IP PORT...` | Logs reachability of the Iran-side IP (ping + ports + tunnel) with timestamps and `CHANGE` lines; run it from the server abroad | Only its own log |
| `scripts/install-monitor.sh IRAN_IP PORT...` | Installs `monitor.sh` as a systemd timer (every 5 min) | Adds a timer |

---

## Support the author

If this saved you time, you can support the work with TRX / USDT on the
**TRON (TRC-20)** network:

```
TYT5gy4y1UKvU55sMS6u5YeHnsA7raYuo1
```

Always copy the address from this repository's default branch and compare the
first and last characters before sending. Sending funds is optional and
irreversible.

---

## License

The documentation and scripts in this repository are released under the
[MIT License](LICENSE). BackPack is a separate project under AGPL-3.0; see
[NOTICE.md](NOTICE.md).
