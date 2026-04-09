---
name: mist-client-troubleshoot
description: >
  Use when the user reports a client connectivity problem, asks why a device
  can't connect, gives a MAC address or hostname to investigate, asks which AP
  or SSID a client is on, wants recent history of a specific device, or asks
  "what's wrong with this client". Triggers on phrases like "client can't connect",
  "why is this device offline", "troubleshoot MAC", "check client",
  "auth failures for user", "client keeps disconnecting", "diagnose connectivity",
  "client dropped", "user can't get IP". Use for any client-level diagnostic question.
---

# Mist Client Troubleshooter

Diagnose client connectivity issues using Marvis AI root cause analysis, session pattern detection, and NAC event correlation.

## Workflow

### Step 0 — Resolve org_id

1. `get_mist_self` → `org_id`.

### Step 1 — Identify the client

Extract MAC or hostname from the user's message (any notation: `aa:bb:cc`, `AA-BB-CC-DD-EE-FF`, `aabbccddeeff`).

```
find_mist_entity(org_id=..., query='<mac_or_hostname>')
```

- **Not found**: tell the user and stop.
- **Multiple matches**: list them, ask user to clarify.
- **Found**: note `entity_type`, `mac`, `site_id`, `site_name`. Proceed.

### Step 2 — Marvis AI root cause analysis

```
get_mist_insights(
  insight_type="troubleshoot",
  org_id=...,
  site_id=<site_id>,
  duration="7d",
  params={"mac": "<compact_mac>", "type": "<connection_type>"}
)
```

**Type selection**: default `wireless`. Use `wired` if entity_type is `wired_client`, `wan` if `wan_client`.

If you get a 403 or license error, skip this step and note "Marvis AI not available — check license."

### Step 3 — Session history and pattern detection

```
search_mist_data(
  scope="org",
  search_type="client_sessions",
  org_id=...,
  site_id=<site_id>,
  filters={"mac": "<compact_mac>"},
  duration="7d",
  limit=25
)
```

Key fields: `connect`, `disconnect` (epoch → human time), `duration` (seconds), `ap`, `ssid`, `tags`, `client_ip`.

**Pattern recognition:**
- Sessions < 10s = repeated auth/association failures
- Regular ~4h sessions = DHCP lease timeout or 802.1X re-auth timer
- Changing IPs every session = DHCP scope issues or aggressive roaming
- `tags` containing `disassociate` or `auth_fail` = specific failure type

### Step 4 — NAC event correlation (if auth issues suspected)

If Marvis output (Step 2) or session tags (Step 3) suggest auth/NAC failures:

```
search_mist_data(
  scope="org",
  search_type="nac_client_events",
  org_id=...,
  filters={"mac": "<compact_mac>"},
  duration="24h",
  limit=25
)
```

NAC events provide RADIUS/802.1X detail: username, auth_type, nacrule_name, deny reason.

### Step 5 — Current session details (if connected)

If the client is currently connected (entity_type indicates active association):

```
get_mist_stats(
  stats_type="site_wireless_clients",
  site_id=<site_id>,
  object_id=<compact_mac>
)
```

Returns RSSI, SNR, band, AP, IP, `tx_bps`/`rx_bps` — useful for "connected but slow" cases.

### Step 6 — Present findings

Lead with the most actionable finding. Structure:

1. **Identity**: MAC, hostname, site, entity type
2. **Current status**: connected/disconnected, AP, SSID, band, RSSI, IP (if connected)
3. **Marvis AI analysis**: root cause, confidence, recommended action (quote directly if specific)
4. **Session history**: top 10 events as timeline, most recent first. Flag anomalies. Summarize patterns rather than listing every session.
5. **Recommended actions**: based on Marvis + event evidence

If the client is not connected, focus on last-seen time and recent failure events.

## Diagnostic interpretation

| Finding | Likely action |
|---|---|
| DHCP failure | Check scope exhaustion, port config, VLAN tagging |
| DNS failure | Verify DNS server reachability, gateway config |
| Auth failure / 802.1X | Check RADIUS server, certificate, NAC policy |
| Missing VLAN | Verify VLAN on switch port / wired uplink |
| Bad cable | Physical inspection, replace cable |
| Low RSSI | AP coverage, band steering, client on wrong AP |
| Roaming issues | 802.11r/k/v config, AP neighbor lists |
| No Marvis result | Rely on session timeline; Marvis may need more data |

## Error handling

| Situation | Action |
|---|---|
| Client not found | "No client matching `<query>` found. Check MAC/hostname." |
| Marvis license error (403) | Skip Marvis, proceed with session data |
| Multiple matching clients | List them, ask user to clarify |
| No sessions in range | Widen duration or report "No sessions found in the last N days." |
