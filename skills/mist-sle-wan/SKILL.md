---
name: mist-sle-wan
description: >
  Retrieve and analyse Mist WAN SLE (Service Level Expectations) data for gateways
  and WAN links. Use this skill whenever the user asks about WAN SLE, gateway health,
  WAN link health, application health, gateway SLE, SD-WAN SLE, WAN assurance,
  WAN link quality, or interface health — at org, site, or gateway level. Triggers on
  phrases like: "WAN SLE", "gateway health score", "WAN link health", "application
  health SLE", "why is WAN SLE low", "which sites have worst gateway health",
  "what's degrading WAN link health", "WAN link is down", "interface health",
  "ISP reachability issues", or any question about Mist WAN quality metrics.
  Always use this skill for SLE analysis of WAN/gateway experience — live data required.
license: Apache-2.0
metadata:
  author: thomas.munzer@hpe.com
  version: "1.0"
---
 
# Mist WAN SLE Analyser
 
Full deep-dive workflow: org-level site ranking → site drill-down → classifier analysis → impacted gateways/interfaces.
 
---
 
## SLE Metric Reference — WAN
 
| Metric | Description | Classifiers (live) |
|---|---|---|
| `gateway-health` | Gateway device health (CPU, memory, temp, tables, DHCP pool) | gateway-disconnected, system-cpu-control-plane, system-cpu-data-plane, system-memory, system-temp-cpu, system-temp-chassis, system-power, table-capacity-fib, table-capacity-flow, dhcp-pool-dhcp-denied, dhcp-pool-dhcp-headroom |
| `wan-link-health` / `wan-link-health-v2` | WAN link quality (latency, jitter, loss, reachability) | interface-congestion, interface-port-down, interface-cable-issues, interface-negotiation-failed, interface-lte-signal, interface-vpn, network-latency, network-jitter, network-loss, network-vpn-path-down, isp-reachability-arp, isp-reachability-dhcp |
| `application-health` | Application performance as seen from the gateway | (query `classifiers` at runtime) |
| `gateway-bandwidth` | Bandwidth utilisation health on gateway interfaces | (query `classifiers` at runtime) |
 
**Preferred versions:** use `wan-link-health-v2` over `wan-link-health` when both enabled.
 
> ⚠️ `wan-link-health-v2 = 0` is common when the metric is enabled but no WAN paths are monitored — check `gateway-bandwidth` as a secondary health indicator in this case.
 
---
 
## SLE Score Thresholds
 
| Score | Status | Icon |
|---|---|---|
| ≥ 95% | Excellent | 🟢 |
| 80–94% | Fair / Warning | 🟡 |
| < 80% | Poor — action required | 🔴 |
| 0 / No data | No WAN paths monitored, or gateway offline | ⚫ |
 
---
 
## Step-by-Step Workflow
 
### Step 0 — Resolve org_id and site names
 
Call `get_mist_self` once if org_id is unknown.
 
Build a site_id → site_name map:
```
get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)
```
 
---
 
### Step 1 — Org-level WAN SLE overview
 
```
get_mist_insights(
  insight_type="sle",
  org_id=...,
  params={"query_type": "sites_sle", "sle": "wan"}
)
```
 
**Response shape:** array of site objects. Sites with no WAN SLE return only `{"site_id": "..."}` (or `{"gateway-health": 0, "site_id": "..."}` for offline gateways) — handle both gracefully.
 
Sites with data:
```json
{
  "site_id": "...",
  "gateway-health": 0.90,
  "wan-link-health": 0.65,
  "wan-link-health-v2": 0.55,
  "application-health": 1.0,
  "gateway-bandwidth": 0.998,
  "num_gateways": 1,
  "num_clients": 4
}
```
 
> ⚠️ `wan-link-health-v2 = 0` when non-null may mean "no paths monitored" — not necessarily an outage. Cross-check `wan-link-health` (v1) and `gateway-health`.
 
**Build the Org Scorecard** — sort by lowest composite SLE:
 
```
## 🌐 WAN SLE — Org Overview (last Xd)
 
Rank  Site               GW-Health  WAN-Link  App-Health  GW-BW   GWs  Clients
 1.   🔴 Branch-Lyon      53%        ⚫         N/A         N/A      1    3
 2.   🔴 Paris-HQ         83%        51%        75%         100%     1    4
 3.   🟡 London-Office    100%       84%        100%        100%     1    3
 4.   🟢 NYC-Office       100%       100%       100%        100%     1    8
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
 
From `enabled` list, filter to WAN metrics: `gateway-health`, `wan-link-health`, `wan-link-health-v2`, `application-health`, `gateway-bandwidth`.
Only proceed with metrics in `enabled`.
 
---
 
### Step 4 — Per-metric summary (classifiers + impact)
 
For each enabled WAN metric:
 
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
- `data.impact.num_users` / `total_users` → WAN clients impacted
- `data.impact.num_aps` / `total_aps` → gateways impacted (field naming from wireless schema)
- `data.classifiers[]` → each with `name`, `impact.num_users`, `impact.num_aps`
 
**Classifier contribution:**
```
share = classifier.impact.num_users / metric.impact.total_users × 100
```
 
---
 
### Step 5 — Impacted gateways and interfaces (for metrics < 90%)
 
**Impacted gateways:**
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "impacted_gateways",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "<metric_name>"
  }
)
```
 
**Impacted WAN interfaces** (especially useful for `wan-link-health`):
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "impacted_interfaces",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "wan-link-health"
  }
)
```
 
Returns per-interface breakdown: `{name, degraded, total}`.
Compute per-interface SLE%: `(1 - degraded/total) × 100`.
Rank worst-first. Show top 5.
 
---
 
## Output Format
 
### Site Drill-Down Report
 
```
## 🌐 WAN SLE — [Site Name] (last 24h)
Total: [N] gateways · [N] WAN clients
 
### Gateway Health — 🟡 83%
  Impacted: 1/1 gateways · 4 clients
 
  Classifiers:
  ├── system-cpu-control-plane:  1 gateway (100%) — control plane CPU spike
  └── system-memory:             1 gateway (100%) — memory pressure
 
  Gateway: SRX-Paris-01  🟡 83%
 
### WAN Link Health — 🔴 51%
  Impacted: 1/1 gateways · 4 clients
 
  Classifiers:
  ├── interface-congestion:    1 interface (100%) — port saturated
  ├── network-latency:         1 interface (100%) — RTT above threshold
  └── isp-reachability-dhcp:   1 interface (50%)  — DHCP unreachable on WAN
 
  Worst Interfaces:
  ├── WAN0  🔴 41%  (degraded for 14.4h/24h)
  └── LTE1  🟡 82%  (degraded for 4.3h/24h)
 
### Application Health — 🟡 74%
  Impacted: 3/4 clients
 
  [classifiers...]
 
### Gateway Bandwidth — 🟢 100%
  No degradation detected.
```
 
### Classifier Interpretation Guide
 
Include for any 🔴 metric:
 
**Gateway Health classifiers:**
| Classifier | What it means | Typical fix |
|---|---|---|
| `gateway-disconnected` | Gateway went offline | Check management connectivity, power, uplink |
| `system-cpu-control-plane` | Control plane CPU spike | High routing churn, BGP reconvergence, management load |
| `system-cpu-data-plane` | Data plane CPU spike | Traffic spike, firewall policy hit rate, DPI load |
| `system-memory` | Memory pressure | Reboot, session table leak, check running version |
| `system-temp-cpu` / `system-temp-chassis` | Temperature alarm | Ventilation, fan failure |
| `system-power` | PSU issue | Check PSU redundancy, power draw |
| `table-capacity-fib` | FIB/route table near full | Too many routes, BGP policy issue |
| `table-capacity-flow` | Flow/session table near full | DDoS, connection leak, NAT exhaustion |
| `dhcp-pool-dhcp-denied` | DHCP pool exhausted | Expand pool, check for rogue clients/leaks |
| `dhcp-pool-dhcp-headroom` | DHCP pool running low | Proactive — expand pool before exhaustion |
 
**WAN Link Health classifiers:**
| Classifier | What it means | Typical fix |
|---|---|---|
| `interface-port-down` | Physical WAN port down | Cable, SFP, ISP CPE issue |
| `interface-cable-issues` | Cable/physical layer errors | Replace cable, check SFP |
| `interface-negotiation-failed` | Speed/duplex negotiation failure | Force speed/duplex settings |
| `interface-congestion` | WAN interface saturated | Upgrade bandwidth, check QoS/traffic shaping |
| `interface-lte-signal` | LTE signal degraded | Antenna positioning, carrier issue |
| `interface-vpn` | VPN tunnel degradation | Peer connectivity, IKE rekeying issues |
| `network-vpn-path-down` | SD-WAN/VPN path down | Check peer-path stats, probe intervals |
| `network-latency` | RTT above threshold | ISP routing issue, path change |
| `network-jitter` | Jitter above threshold | QoS prioritisation, ISP issue |
| `network-loss` | Packet loss detected | Physical layer, ISP, congestion |
| `isp-reachability-arp` | ISP gateway not responding to ARP | CPE/ISP issue, check next-hop |
| `isp-reachability-dhcp` | WAN DHCP server unreachable | ISP DHCP issue, check uplink |
 
---
 
## Error Handling
 
| Situation | Action |
|---|---|
| `wan-link-health-v2 = 0` alongside v1 data | Note "WAN path monitoring may not be configured — v2 = 0" |
| `gateway-health = 0` | Gateway is likely offline — note this prominently |
| Site has no WAN data | Skip — note "⚫ No WAN SLE data (no gateways or unlicensed)" |
| `impacted_interfaces` empty | Note "No interface-level breakdown available" |
| Site name not found | Use `search_mist_data(search_type='sites', filters={name: <query>})` |
 