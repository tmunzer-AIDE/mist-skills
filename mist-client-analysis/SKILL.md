---
name: mist-client-analysis
description: >
  Use when the user asks about wireless or wired clients: application usage,
  bandwidth consumption, client association timelines, manufacturer filtering
  (Intel, Raspberry Pi, Zebra), VLAN membership, traffic rankings, 6 GHz clients,
  interband roaming, clients on a specific switch, or top sites by usage.
  Triggers on phrases like "what apps is client using", "bandwidth used",
  "top clients by bytes", "6 GHz clients", "clients that roamed",
  "clients connected to switch", "top sites by usage", "Raspberry Pi clients",
  "show client timeline". Use this for any client-level or site-level usage question.
---

# Mist Client & Usage Analyser

Look up clients by name/MAC, analyse application usage, bandwidth, roaming behaviour, and rank clients or sites by traffic — all from live Mist data.

## Workflow

### Step 0 — Resolve identities

1. `get_mist_self` → `org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. Only fetch the full site list (`get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`) when you need a complete site map (e.g., org-wide or ranking queries).
3. If the user provides a client name or MAC, resolve it: `find_mist_entity(org_id=..., query='<name_or_mac>')`. Note the `entity_type`, `mac`, `site_id`.

### Step 1 — Route by question type

| User intent | Go to |
|---|---|
| Application usage for a client | Step 2 |
| Bandwidth / bytes used by a client | Step 3 |
| Client association timeline (AP history) | Step 4 |
| Filter clients by manufacturer (OUI) | Step 5 |
| Check VLAN membership | Step 6 |
| Rank clients by TX/RX bytes | Step 7 |
| 6 GHz clients | Step 8 |
| Interband roaming detection | Step 9 |
| Clients connected to a specific switch | Step 10 |
| Top sites by usage | Step 11 |
| Application usage at a site | Step 12 |

### Step 2 — Application usage per client

1. Call `get_mist_insights(insight_type='insight_metrics', site_id=..., duration='1d', params={object_type:'client', metric:'top-app-by-bytes', mac:'<compact_mac>'})`.
2. If the metric name is wrong, discover available metrics first: `get_mist_constants(constant_type='insight_metrics')` and look for app-related metrics.
3. Present app name, bytes, and percentage of total.

### Step 3 — Bandwidth / bytes used

1. Get live client stats: `get_mist_stats(stats_type='site_wireless_clients', site_id=..., object_id='<compact_mac>')`.
2. Extract `tx_bytes` and `rx_bytes`. Format as human-readable (KB/MB/GB).
3. If client is not currently connected, search recent sessions: `search_mist_data(scope='org', search_type='client_sessions', org_id=..., filters={mac:'<compact_mac>'}, duration='1d')` and sum data if available.

### Step 4 — Association timeline

1. `search_mist_data(scope='org', search_type='client_sessions', org_id=..., filters={mac:'<compact_mac>'}, duration='7d', limit=100)`. Paginate.
2. Build AP MAC → AP name map: `get_mist_stats(stats_type='site_devices', site_id=..., filters={type:'ap'})`.
3. For each session, extract: `connect` (epoch → human time), `disconnect`, `duration`, `ap` (→ AP name), `band`, `ssid`.
4. Present as a chronological timeline. Flag anomalies: sessions < 10s (likely failures), rapid AP changes (roaming issues).

### Step 5 — Filter by manufacturer (OUI)

1. `search_mist_data(scope='org', search_type='wireless_clients', org_id=..., duration='7d', limit=100)`. Add `site_id` filter if site specified. Paginate fully.
2. Filter results where `mfg` contains the manufacturer string (case-insensitive). Examples: "Intel Corporate", "Raspberry Pi Trading Ltd", "Apple, Inc."
3. For each matched client, show: hostname, MAC, manufacturer, last_ap, last_ssid, last_os, last_ip.
4. If user wants application summary for policy building, follow up with Step 2 for each matched client.

### Step 6 — VLAN membership check

1. Resolve client: `find_mist_entity(org_id=..., query='<mac>')`.
2. Search: `search_mist_data(scope='org', search_type='wireless_clients', org_id=..., filters={mac:'<compact_mac>'}, duration='1d')`.
3. Check `last_vlan` or `vlan` array in results. Compare against the requested VLAN number.
4. Also check wired clients: `search_mist_data(scope='org', search_type='wired_clients', org_id=..., filters={mac:'<compact_mac>'})`.

### Step 7 — Rank clients by TX/RX throughput

1. Use `get_mist_stats(stats_type='site_wireless_clients', site_id=...)` to get all currently connected clients with live stats. Paginate fully.
2. If no site specified, identify the target site first via Step 11 or the user's context.
3. Sort by `tx_bps + rx_bps` descending (real-time throughput in bits/sec). Take top N.
4. Present: rank | hostname | MAC | TX rate | RX rate | total rate | AP | SSID. Format bps as Kbps/Mbps.
5. Note: this shows only currently connected clients with real-time rates. For historical byte totals, use `search_mist_data(search_type='client_sessions')` and sum session data if available.

### Step 8 — 6 GHz clients

1. `search_mist_data(scope='org', search_type='wireless_clients', org_id=..., filters={band:'6'}, duration='1d')`. Add `site_id` if scoped. Paginate.
2. Present: hostname, MAC, manufacturer, AP, SSID, protocol.

### Step 9 — Interband roaming

1. Get client sessions: `search_mist_data(scope='org', search_type='client_sessions', org_id=..., filters={mac:'<compact_mac>'}, duration='7d', limit=100)`. Paginate.
2. Sort by `connect` timestamp ascending.
3. Walk sessions: if consecutive sessions have different `band` values and the gap between disconnect→connect is < 5 minutes, that's an interband roam.
4. Present: timestamp | from band | to band | from AP | to AP.

### Step 10 — Clients on a specific switch

1. Resolve switch: `find_mist_entity(org_id=..., query='<switch_name>', entity_types=['device'])`.
2. Get switch MAC from results.
3. Search wired clients: `search_mist_data(scope='org', search_type='wired_clients', org_id=..., filters={device_mac:'<switch_mac>'}, duration='1d')`. Paginate.
4. Present: hostname, MAC, IP, port, VLAN.

### Step 11 — Top sites by usage

1. `get_mist_stats(stats_type='sites', org_id=..., duration='7d')`. Paginate.
2. Sort by `num_clients` (most connected clients) or `tx_bytes + rx_bytes` if available. The `num_clients` field is the most reliable ranking metric.
3. Present top N with: site name | client count | AP count | usage metric.

### Step 12 — Application usage at site level

1. Resolve the site (by name or by feature like "site with SSR" → search for sites with gateway type SSR).
2. `get_mist_insights(insight_type='insight_metrics', site_id=..., duration='1d', params={object_type:'site', metric:'top-app-by-bytes'})`.
3. Present: app name | bytes | percentage.

## Data formatting

- **Bytes:** auto-scale to KB/MB/GB (1 GB = 1,073,741,824 bytes)
- **Timestamps:** convert epoch seconds to `YYYY-MM-DD HH:MM` in local timezone context
- **Duration:** convert seconds to `Xh Ym` (e.g., 3661 → "1h 1m")
- **MAC:** display with colons (aa:bb:cc:dd:ee:ff) for readability
- **Band:** "24" → "2.4 GHz", "5" → "5 GHz", "6" → "6 GHz"

## Output

Use canvas (`web-artifacts-builder`) for rich results when there's substantial data — client dashboards, timeline charts, ranking tables. Use markdown tables for simple lookups.

## Error handling

| Situation | Action |
|---|---|
| Client not found | "No client matching '<query>' found. Check MAC/hostname and retry." |
| No sessions in range | Widen the duration or report "No sessions found in the last N days." |
| Site name not found | Fuzzy-match with `search_mist_data(search_type='sites', filters={name:'...'})` |
| Metric not available | Call `get_mist_constants(constant_type='insight_metrics')` to discover available metrics |
| Switch not found | Search by hostname: `search_mist_data(search_type='devices', filters={hostname:'...'})` |
