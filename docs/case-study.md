# Case study: a flapping BackPack tunnel

[فارسی](case-study.fa.md)

All IP addresses and tokens are replaced with placeholders:
`KHAREJ` = server abroad that runs the services (x-ui / n8n),
`IRAN` = entry server that users connect to.

## Setup before the problem

- `IRAN` listens on the tunnel port and on the user-facing ports.
- `KHAREJ` dials `IRAN` (a **Reverse** tunnel, transport `tcp`).
- Forwarded ports: `80, 8080, 8443, 3053, 2087, 2053, 8081, 8082, 8083, 2083`
  and `443` mapped to a third host.

## Timeline of the investigation

1. **Symptom.** `journalctl -u backpack-bpt` on KHAREJ showed
   `nothing heard from the server for 15s` followed by `restarting client`,
   about every 17 s.
2. **Everything else was healthy.** SSH worked, the containers were up,
   CPU/RAM/disk were fine, ping to IRAN was ~77 ms with 0 % loss, and the
   tunnel port was open. A packet capture (`tcpdump`) showed packets flowing in
   both directions.
3. **Things that did NOT help** (so you can skip them):
   - Adding `heartbeat = 10` to the client config.
   - Switching `transport` from `tcp` to `ws` on both ends.
   - Restarting both services in a controlled order.
   - Rebuilding the tunnel from scratch with a new token.
   - Changing the tunnel port.
   - Faster server heartbeat (3 s).
   - Raising `keepalive_period` to 75 s.
   - Re-running the installer (the binary is byte-identical; same md5 on both
     ends).
4. **What finally showed the cause.** BackPack's **Connection Test**
   (`sudo backpack` → `0`) measures every transport between the two servers:

   | Transport | Result |
   |---|---|
   | Reverse PCK | OK 60/60, 54 Mbps, 78 ms |
   | Direct PCK | OK 60/60, 22.6 Mbps |
   | Direct xDi | OK 60/60, 19.4 Mbps |
   | Reverse UDP | unstable 92 % |
   | Reverse TCP | unstable 85 % |
   | Reverse WS / WSS | unstable 77 % / 72 % |
   | QUIC, SNI, IP spoof | down |

   The path between the two data centres handled raw TCP-like (PCK) flows well
   but was lossy for ordinary long-lived TCP and WebSocket connections.
5. **Reverse PCK helped but not enough.** It cut the flap rate from every
   ~17 s to about every 30-60 s, still not acceptable.
6. **Direct PCK fixed it.** The Direct mode is a layer-3 tunnel (interface
   `bp0`, `10.10.0.1` ↔ `10.10.0.2`), and the wizard can forward ports itself.
   After creating it, a 2.5-minute watch showed **zero** reconnects, 0 % ping
   loss, and all forwarded ports answered, including TLS handshakes through
   the tunnel.

## Lessons

- A tunnel that "connects" is not necessarily healthy. Look at heartbeat/flap
  counts, not just `active (running)`.
- Do not tune timers blindly. Measure the path with the Connection Test first.
- Keep a backup of `/etc/backpack/` before every change. Every config change
  here was reversible within seconds.
- When you stop the old tunnel service, remember it holds the same ports the
  new tunnel wants to listen on.
