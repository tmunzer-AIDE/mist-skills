---
name: mist-sle-wireless
description: >
  Retrieve and analyse Mist Wireless SLE (Service Level Expectations) data.
  Use this skill whenever the user asks about WiFi or wireless SLE, AP health,
  coverage scores, time-to-connect, roaming quality, throughput SLE, capacity SLE,
  or successful-connect rates — at org, site, or AP level. Triggers on phrases like:
  "wireless SLE", "WiFi SLE", "AP health score", "coverage SLE", "time to connect",
  "roaming SLE", "why is wireless SLE low", "which sites have worst WiFi SLE",
  "what's degrading coverage", "how is the wireless experience", or any question
  about Mist wireless quality metrics. Always use this skill for SLE analysis
  of wireless/WiFi — do not try to answer from memory, the live data matters.
license: Apache-2.0
metadata:
  author: thomas.munzer@hpe.com
  version: "1.0"
---
 
# Mist Wireless SLE Analyser
 
Full deep-dive workflow: org-level site ranking → site drill-down → classifier analysis → impacted APs/clients.
 
---
 
## SLE Metric Reference — Wireless
 
| Metric | Description | Classifiers (live) |
|---|---|---|
| `coverage` | % of client-time with adequate RSSI | weak-signal, asymmetry-uplink, asymmetry-downlink |
| `capacity` | % of client-time with adequate airtime capacity | channel-interference, channel-utilization, non-wifi-interference, insufficient-coverage |
| `time-to-connect` | % of connections completing within threshold | dhcp-nack, dhcp-unresponsive, dhcp-stuck, authorization, association, IP-Services |
| `roaming` | % of roam events completing successfully and quickly | roam-slow, roam-failed, fast-roam-okc-slow, fast-roam-11r-slow, fast-roam-failed |
| `throughput` | % of client-time with adequate throughput | insufficient-bandwidth, slow-link-speed |
| `ap-health` | AP hardware + RF health composite | (varies; query `classifiers` at runtime) |
| `ap-availability` | % of time APs are online | reboots, outages |
| `successful-connect` / `failed-to-connect` | Connection success rate | (query `classifiers` at runtime) |
 
**Preferred metric names (use v2/current when available):**  
- Wired health: `switch-health-v2` preferred over `switch-health`  
- Always call `query_type=metrics` first to get enabled/supported metric list for the site
 
---
 
## SLE Score Thresholds
 
| Score | Status | Icon |
|---|---|---|
| ≥ 95% | Excellent | 🟢 |
| 80–94% | Fair / Warning | 🟡 |
| < 80% | Poor — action required | 🔴 |
| No data / N/A | Site has no wireless, or SLE unlicensed | ⚫ |
 
---
 
## Step-by-Step Workflow
 
### Step 0 — Resolve org_id and site names
 
Call `get_mist_self` once if org_id is unknown.
 
To display human-readable site names alongside site_ids, call:
```
get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)
```
Build a `site_id → site_name` map. Reuse throughout this session.
 
---
 
### Step 1 — Org-level wireless SLE overview
 
```
get_mist_insights(
  insight_type="sle",
  org_id=...,
  params={"query_type": "sites_sle", "sle": "wifi"}
)
```
 
**Response shape:** array of site objects. Sites with no wireless data return `{"site_id": "..."}` only (no metric keys) — skip these silently.
 
Sites with data return metric keys like:
```json
{
  "site_id": "...",
  "coverage": 0.83,
  "capacity": 0.75,
  "time-to-connect": 0.97,
  "roaming": 0.92,
  "throughput": 0.99,
  "ap-health": 0.92,
  "num_aps": 12,
  "num_clients": 32
}
```
 
**Build the Org Scorecard** — sort by lowest composite SLE:
- Composite = average of all available metric scores for that site
- Rank sites worst-first
 
Display as a ranked table:
 
```
## 📶 Wireless SLE — Org Overview (last Xd)
 
Rank  Site                Coverage  Capacity  TTC    Roaming  Throughput  AP-Health  APs  Clients
 1.   🔴 Acme-Paris        72%       68%       91%    88%      99%         77%         3    14
 2.   🟡 HQ-London         85%       91%       94%    96%      97%         83%         12   32
 3.   🟢 NYC-Office        96%       95%       99%    98%      99%         98%         5    22
```
 
---
 
### Step 2 — Identify site(s) to drill into
 
If the user named a site → resolve it using the site name map.
If not specified → automatically drill into the **worst** site (rank 1).
If multiple sites are in 🔴 status → drill into all of them.
 
---
 
### Step 3 — Get enabled metrics for the site
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  params={"query_type": "metrics", "scope": "site", "scope_id": <site_id>}
)
```
 
Returns `{"enabled": [...], "supported": [...]}`.
Use the `enabled` list to know which metrics have data. Only proceed with metrics in `enabled`.
 
---
 
### Step 4 — Per-metric summary (classifiers + impact)
 
For **each enabled metric** (run these in order; for metrics scoring ≥ 95% you may skip unless user asked for full breakdown):
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",   # or match user's requested time range
  params={
    "query_type": "summary",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "<metric_name>"
  }
)
```
 
**Extract from response:**
- `data.sle.samples.degraded` / `data.sle.samples.total` → compute SLE%: `sum(degraded)/sum(total)` (the score from sites_sle is more reliable if available — prefer that)
- `data.impact.num_users` / `data.impact.total_users` → % of users impacted
- `data.impact.num_aps` / `data.impact.total_aps` → % of APs impacted
- `data.classifiers[]` → each classifier has:
  - `name`: classifier identifier
  - `impact.num_users` / `impact.total_users`: users affected by this specific classifier
  - `impact.num_aps` / `impact.total_aps`: APs affected
 
**Compute classifier contribution:**
```
classifier_share = classifier.impact.num_users / metric.impact.total_users × 100
```
 
---
 
### Step 5 — Impacted APs (for metrics scoring < 90%)
 
```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "impacted_aps",
    "scope": "site",
    "scope_id": <site_id>,
    "metric": "<metric_name>"
  }
)
```
 
Returns array: `{ap_mac, name, degraded, total}` per AP.
Compute per-AP SLE%: `(1 - degraded/total) × 100`.
Rank APs worst-first. Show top 5 worst.
 
For `time-to-connect` or `successful-connect` failures, also fetch impacted clients:
```
params={"query_type": "impacted_wireless_clients", ...}
```
 
---
 
## Rendering — Visualizer Dashboard
 
After gathering all data, **always render a visual dashboard using `show_widget`** before writing any prose summary. Call `read_me` with `modules=["interactive"]` first.
 
### Dashboard design spec
 
Use HTML mode. Build a self-contained dark NOC dashboard — all data embedded as JS variables, no external API calls from the widget. Target width: 700px, height auto.
 
**Color palette (use as CSS vars):**
```css
--bg:      #0f172a;   /* slate-900 — main background */
--surface: #1e293b;   /* slate-800 — card background */
--border:  #334155;   /* slate-700 — dividers */
--good:    #22c55e;   /* green-500  ≥ 95% */
--warn:    #f59e0b;   /* amber-500  80–94% */
--bad:     #ef4444;   /* red-500    < 80% */
--muted:   #64748b;   /* slate-500  no data */
--text:    #f1f5f9;   /* slate-100  primary text */
--sub:     #94a3b8;   /* slate-400  secondary text */
```
 
**Layout (top → bottom):**
 
1. **Header strip** — site name (bold), time range (muted), device summary (APs · Clients)
 
2. **Metric score grid** — one card per enabled metric, 3–4 columns:
   - Large bold score percentage, coloured by threshold
   - Metric label below
   - Thin coloured arc or left-border accent bar
   - Small "N users affected" if degraded
 
3. **Classifier breakdown** (only for metrics < 95%) — one row per degraded metric:
   - Metric name + score badge
   - Horizontal stacked bar showing classifier proportions (coloured segments)
   - Legend below: classifier name + user count
 
4. **Worst APs table** (only for metrics < 90%) — compact table:
   - AP name | Score bar | Score % | Degraded / Total user-min
 
5. **Footer** — "Data: last 24h · Mist Wireless SLE" in muted text
 
**Micro-details:**
- Animate score numbers counting up from 0 on load (CSS counter or JS setInterval)
- Hover on classifier segments → tooltip with classifier name + exact %
- Score cards: slightly lighter border on hover
- No chart.js dependency needed — use pure CSS/SVG for bars and arcs
 
### Example JS data shape to embed
 
```javascript
const data = {
  site: "Live Demo",
  duration: "24h",
  aps: 12, clients: 91,
  metrics: [
    { name: "Capacity",         label: "capacity",         score: 75, users_affected: 75, total_users: 88,
      classifiers: [
        { name: "wifi-interference", users: 71, color: "#ef4444" },
        { name: "client-usage",      users: 50, color: "#f59e0b" }
      ],
      worst_aps: [
        { name: "LD_Kitchen2",  score: 23, degraded: 3393, total: 4385 },
        { name: "LD_PLM1_AP",   score: 61, degraded:  856, total: 2175 }
      ]
    },
    { name: "Coverage", label: "coverage", score: 83, users_affected: 67, total_users: 91,
      classifiers: [
        { name: "weak-signal",      users: 61, color: "#ef4444" },
        { name: "asymmetry-uplink", users: 28, color: "#f59e0b" }
      ],
      worst_aps: []
    },
    { name: "Throughput",       label: "throughput",        score: 99, users_affected: 0, total_users: 91, classifiers: [], worst_aps: [] },
    { name: "Time-to-Connect",  label: "time-to-connect",   score: 97, users_affected: 0, total_users: 91, classifiers: [], worst_aps: [] },
    { name: "AP Health",        label: "ap-health",         score: 92, users_affected: 8, total_users: 91, classifiers: [], worst_aps: [] },
    { name: "Roaming",          label: "roaming",           score: 91, users_affected: 8, total_users: 91, classifiers: [], worst_aps: [] }
  ]
};
```
 
After rendering the widget, write a **brief prose summary** (3–5 sentences max) covering the critical issues and recommended actions. Do not repeat what the dashboard already shows visually.
 
---
 
## Output Format (prose fallback — if Visualizer unavailable)
 
### Site Drill-Down Report
 
```
## 📶 Wireless SLE — [Site Name] (last 24h)
Total: [N] APs · [N] Clients · [N] SSIDs
 
### Coverage — 🔴 72% (↓23% below baseline)
  Impacted: 67/91 users (74%) · 12/12 APs (100%)
  
  Classifiers:
  ├── weak-signal:       61 users (91%) — RSSI avg -60 dBm vs -50 dBm baseline
  └── asymmetry-uplink:  27 users (40%) — uplink asymmetry detected
 
  Worst APs:
  ├── LD_Marvis      🔴 38%  (1434/2328 user-minutes degraded)
  ├── LD_BFriday     🔴 43%  (844/1487)
  └── LD_PLM1_AP     🔴 71%  (600/2095)
 
### Capacity — 🟡 75%
  Impacted: 45/91 users (49%) · 8/12 APs (67%)
  [classifiers + worst APs...]
 
### Time-to-Connect — 🟢 97%
  [brief summary only — no drill-down needed]
 
### AP Health — 🟡 92%
  [classifiers + worst APs...]
```
 
### Classifier Interpretation Guide
 
Include in output for any 🔴 metric:
 
| Classifier | What it means | Typical fix |
|---|---|---|
| `weak-signal` | Clients seeing RSSI below threshold | AP placement, Tx power, roaming thresholds |
| `asymmetry-uplink` | Client can hear AP but AP can't hear client | Client Tx power too low, distance |
| `dhcp-nack` / `dhcp-unresponsive` | DHCP failures | DHCP scope, relay config, server reachability |
| `authorization` | 802.1X / PSK auth failures | RADIUS config, certificate, password mismatch |
| `roam-failed` | Clients can't find or join new AP | 802.11r/k/v config, neighbor lists, band steering |
| `channel-interference` | Co-channel or adjacent interference | RRM tuning, channel plan |
| `reboots` | APs rebooting frequently | Power, firmware bug, crash loop |
| `outages` | APs going offline | Uplink switch, PoE, connectivity |
 
---
 
## Error Handling
 
| Situation | Action |
|---|---|
| Site has no wireless data | Skip silently, note in output: "⚫ No wireless SLE data" |
| Metric not in `enabled` list | Skip — SLE not licensed or no data for that metric |
| `summary` fails with 400 | Try `duration="7d"` — short windows sometimes have no data |
| `impacted_aps` returns empty | Note "No AP-level breakdown available" |
| Site name not found | Use `search_mist_data(search_type='sites', filters={name: <query>})` to resolve |
 