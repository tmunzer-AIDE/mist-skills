---
name: mist-sle-wired
description: >
  Retrieve and analyse Mist Wired SLE (Service Level Expectations) data for switches.
  Use this skill whenever the user asks about wired SLE, switch health, switch SLE,
  switch throughput, PoE health, wired assurance, switch-stc, or wired experience scores
  — at org, site, or switch level. Triggers on phrases like: "wired SLE", "switch SLE",
  "switch health score", "switch throughput SLE", "why is wired SLE low",
  "which sites have worst switch health", "what's degrading switch-health",
  "how are my switches performing", "wired assurance score", or any question about
  Mist wired quality metrics. Always use this skill for SLE analysis of wired/switch
  experience — do not answer from memory, live data is required.
license: Apache-2.0
metadata:
  author: thomas.munzer@hpe.com
  version: "1.0"
---
 
# Mist Wired SLE Analyser
 
Full deep-dive workflow: org-level site ranking → site drill-down → classifier analysis → impacted switches/clients.
 
---
 
## SLE Metric Reference — Wired
 
| Metric | Description | Classifiers (live) |
|---|---|---|
| `switch-health-v2` | Switch device health composite (CPU, memory, temp, tables, WAN) | switch-unreachable, network-wan-latency, network-wan-jitter, system-cpu, system-memory, system-power, system-temp, capacity-route-table, capacity-arp-table, capacity-mac-address-table |
| `switch-throughput` | % of time switch ports operate at good throughput | (query `classifiers` at runtime) |
| `switch-bandwidth` / `switch-bandwidth-v2` | Bandwidth utilisation health | (query `classifiers` at runtime) |
| `switch-stc` / `switch-stc-v4` | Switch successful-to-connect for wired clients | (query `classifiers` at runtime) |
 
**Preferred versions:** use `switch-health-v2`, `switch-bandwidth-v2`, `switch-stc-v4` over their non-versioned counterparts when enabled.
 
---
 
## SLE Score Thresholds
 
| Score | Status | Icon |
|---|---|---|
| ≥ 95% | Excellent | 🟢 |
| 80–94% | Fair / Warning | 🟡 |
| < 80% | Poor — action required | 🔴 |
| No data | Site has no switches, or SLE unlicensed | ⚫ |
 
---
 
## Step-by-Step Workflow
 
### Step 0 — Resolve org_id and site names
 
Call `get_mist_self` once if org_id is unknown.
 
Build a site_id → site_name map:
```
get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)
```
 
---
 
### Step 1 — Org-level wired SLE overview
 
```
get_mist_insights(
  insight_type="sle",
  org_id=...,
  params={"query_type": "sites_sle", "sle": "wired"}
)
```
 
**Response shape:** array of site objects. Sites with no wired SLE data return only `{"site_id": "..."}` — skip these silently.
 
Sites with data:
```json
{
  "site_id": "...",
  "switch-health-v2": 0.997,
  "switch-throughput": 1.0,
  "switch-bandwidth-v2": 1.0,
  "switch-stc": 1.0,
  "num_switches": 5,
  "num_clients": 49
}
```
 
**Build the Org Scorecard** — sort by lowest composite SLE (average of available metrics):
 
```
## 🔌 Wired SLE — Org Overview (last Xd)
 
Rank  Site                Sw-Health  Sw-Throughput  Sw-BW  Sw-STC  Switches  Clients
 1.   🔴 Branch-Lyon       63%        98%            100%   N/A      1         2
 2.   🟡 HQ-Paris          83%        100%           100%   100%     5         49
 3.   🟢 London-Office     100%       100%           100%   100%     1         6
```
 
---
 
### Step 2 — Identify site(s) to drill into
 
If the user named a site → resolve using site name map.
If not specified → drill into the **worst** site (rank 1).
Multiple 🔴 sites → drill into all of them.
 
---
 
### Step 3 — Get enabled metrics for the site
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  params={"query_type": "metrics", "scope": "site", "scope_id": <site_id>}
)
```
 
From `enabled` list, filter to wired metrics: those starting with `switch-`.
Only proceed with metrics that are in `enabled`.
 
---
 
### Step 4 — Per-metric summary (classifiers + impact)
 
For each enabled wired metric:
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "summary",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "<metric_name>"
  }
)
```
 
**Extract from response:**
- `data.impact.num_users` / `total_users` → % wired clients impacted
- `data.impact.num_aps` / `total_aps` → note: for wired, this counts switches in the `total_aps` field (naming is inherited from wireless schema)
- `data.classifiers[]` → each with `name`, `impact.num_users`, `impact.num_aps`
 
**Classifier contribution:**
```
share = classifier.impact.num_users / metric.impact.total_users × 100
```
 
---
 
### Step 5 — Impacted switches (for metrics < 90%)
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "impacted_switches",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "<metric_name>"
  }
)
```
 
Returns array: `{mac, name, degraded, total}` per switch.
Compute per-switch SLE%: `(1 - degraded/total) × 100`.
Rank worst-first, show top 5.
 
For client-affecting metrics (`switch-stc`), also check:
```
params={"query_type": "impacted_wired_clients", ...}
```
 
---
 
## Output Format
 
### Site Drill-Down Report
 
```
## 🔌 Wired SLE — [Site Name] (last 24h)
Total: [N] switches · [N] wired clients
 
### Switch Health (v2) — 🔴 77%
  Impacted: 2/2 switches (100%) · 6/6 clients (100%)
 
  Classifiers:
  ├── switch-unreachable:      2 switches (100%) — switch went offline
  ├── network-wan-latency:     1 switch  (50%)  — WAN RTT above threshold
  └── system-cpu:              1 switch  (50%)  — CPU spike detected
 
  Worst Switches:
  ├── EX2300-Core    🔴 61%  (38/62 user-minutes degraded)
  └── EX3400-Dist    🟡 82%  (11/62)
 
### Switch Throughput — 🟢 100%
  No degradation detected.
 
### Switch STC (v4) — 🟢 100%
  All wired clients connected successfully.
```
 
### Classifier Interpretation Guide
 
Include for any 🔴 metric:
 
| Classifier | What it means | Typical fix |
|---|---|---|
| `switch-unreachable` | Switch disconnected from Mist | Check uplink, power, management VLAN reachability |
| `system-cpu` | CPU utilisation above threshold | Check for broadcast storms, spanning tree issues, high control-plane traffic |
| `system-memory` | Memory exhaustion | Reboot, check for memory leak in running version |
| `system-temp` | Temperature above threshold | Check rack ventilation, fan status |
| `system-power` | PoE or PSU issue | Check PoE budget, PSU redundancy |
| `network-wan-latency` | High latency on WAN-facing uplink | ISP issue, QoS misconfiguration |
| `network-wan-jitter` | Jitter on WAN uplink | Same as latency — WAN path quality |
| `capacity-arp-table` | ARP table near capacity | Network design issue — too many hosts/subnets, check for ARP flooding |
| `capacity-mac-address-table` | MAC table near capacity | Possible MAC flooding attack, or overly large L2 domain |
| `capacity-route-table` | Route table near capacity | Too many routes, check BGP/OSPF prefixes |
 
---
 
## Error Handling
 
| Situation | Action |
|---|---|
| Site has no wired data | Skip — note "⚫ No wired SLE data (no switches or unlicensed)" |
| Metric not in `enabled` | Skip — note metric is not enabled |
| `summary` fails with 400 | Try `duration="7d"` |
| `impacted_switches` empty | Note "No switch-level breakdown available" |
| Site name not found | Use `search_mist_data(search_type='sites', filters={name: <query>})` |