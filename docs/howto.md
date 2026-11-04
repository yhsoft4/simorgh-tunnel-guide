# How-to: replace a flapping tunnel with Direct PCK

[فارسی](howto.fa.md)

Run everything as root. `IRAN` is the entry server users connect to; `KHAREJ`
is the server abroad running the services. Names follow BackPack's own menu.

## 0. Back up first

On both servers:

```bash
tar czf /root/backpack-etc-$(date +%s).tgz /etc/backpack
```

## 1. Measure the path (Connection Test)

1. On IRAN: `sudo backpack` → `0` → `1` (Iran) → Enter (default IP) → pick a
   preset (Turbo is fine on a big VPS, Balance on a 1 GB VPS). A link
   `backpack://t....` appears. Leave this window open.
2. On KHAREJ: `sudo backpack` → `0` → `2` (Kharej) → paste the link.
3. Wait about 4 minutes. Read **Works Steadily** and **BEST SETTINGS**.

Tip: run the menu inside `screen` so an SSH drop does not kill the test.

## 2. Stop the old tunnel

The old tunnel service holds the ports the new one needs.

```bash
# IRAN
systemctl stop backpack-bpt
# KHAREJ
systemctl stop backpack-bpt && systemctl disable backpack-bpt
```

(Service names may differ; `systemctl list-units 'backpack*'` shows yours.)

## 3. Create the Direct tunnel on IRAN

`sudo backpack` → `1` (Setup Iran) → `2` (Direct) → `2` (PCK) →
KHAREJ IP → tunnel port (default 9000) → forwarded ports.

The forwarded-ports field accepts a comma list. To send one port to a different
host use `PORT=HOST:PORT`:

```
80,8080,8443,3053,2087,2053,8081,8082,8083,2083,443=203.0.113.10:443
```

Then: accept the name and token, answer `y` to *UDP as well as TCP* if you need
UDP, `n` to FEC, choose a preset, `n` to advanced settings, `0` for auto
restart, `Y` to create. The wizard prints a **setup link** and a ready command.

## 4. Apply the link on KHAREJ

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh) \
  link apply 'backpack://2....'
```

Treat the setup link like a password: it contains the tunnel token.

## 5. Verify

```bash
bash scripts/diagnose.sh                       # on either server
bash scripts/check-ports.sh IRAN_IP 80 443 2053
ping -c5 10.10.0.2                             # from IRAN, through the tunnel
```

Look for: interface `bp0` up, 0 reconnects over a few minutes, 0 % ping loss.

## Rolling back

Restore the backup, then `systemctl start backpack-bpt` on both servers and stop
the new `backpack-l3-*` services.

## Remove access you granted

If you gave someone (or an assistant) SSH access to a server to help, remove
their line from `~/.ssh/authorized_keys` afterwards.
