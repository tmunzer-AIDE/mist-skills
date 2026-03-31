---
name: mist-sle
description: >
  Use when the user asks about SLE (Service Level Expectations) for wireless,
  wired, or WAN. Covers Wi-Fi SLE (coverage, capacity, roaming, throughput,
  time-to-connect, AP health), switch/wired SLE (switch health, switch throughput,
  switch bandwidth, switch STC), and WAN/gateway SLE (gateway health, WAN link
  health, application health, gateway bandwidth). Triggers on phrases like
  "SLE score", "coverage SLE", "switch health", "WAN link health", "which site
  has worst SLE", "what's degrading capacity", "impacted APs", "worst switches",
  "gateway health", "AP SLE below 40%", "wired assurance", "WAN assurance",
  or any question about Mist service level metrics.
---

# Mist SLE Analyser

Unified SLE workflow for wireless, wired, and WAN: org-level site ranking, site drill-down, classifier breakdown, and impacted entity analysis.

## SLE Domains

| Domain | sle param | Metric prefix | Entity queries |
|---|---|---|---|
| Wireless | `wifi` | coverage, capacity, time-to-connect, roaming, throughput, ap-health, ap-availability, successful-connect, failed-to-connect | impacted_aps, impacted_wireless_clients |
| Wired | `wired` | switch-health-v2, switch-throughput, switch-bandwidth-v2, switch-stc-v4 | impacted_switches, impacted_wired_clients |
| WAN | `wan` | gateway-health, wan-link-health-v2, application-health, gateway-bandwidth | impacted_gateways, impacted_interfaces |

See [references/metrics.md](references/metrics.md) for full metric details, classifiers, and interpretation guides.

## Score thresholds

| Score | Status |
|---|---|
| >= 95% | Excellent (green) |
| 80–94% | Warning (yellow) |
| < 80% | Poor — action required (red) |
| 0 / No data | No devices or SLE unlicensed |

## Workflow

### Step 0 — Resolve org_id and sites

1. `get_mist_self` → `org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. For the org-level SLE overview (Step 2), you'll need the full site list for the name map: `get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`. Paginate if `has_more`.

### Step 1 — Determine the SLE domain

From the user's question, identify the domain:
- Wireless: mentions coverage, capacity, roaming, throughput, AP health, Wi-Fi SLE, wireless assurance
- Wired: mentions switch health, switch SLE, wired assurance, switch throughput
- WAN: mentions gateway health, WAN link, application health, WAN SLE, SD-WAN

Set `sle_domain` to `"wifi"`, `"wired"`, or `"wan"`.

### Step 2 — Org-level SLE overview

```
get_mist_insights(
  insight_type="sle",
  org_id=...,
  params={"query_type": "sites_sle", "sle": "<sle_domain>"}
)
```

Returns an array of site objects. Sites with no data return only `{"site_id": "..."}` — skip these.

Sites with data contain metric scores as decimal values (0.83 = 83%), plus `num_aps` / `num_switches` / `num_gateways` and `num_clients`.

Build a ranked scorecard sorted by lowest composite SLE. Composite = arithmetic mean of all numeric metric scores present for that site (e.g., if a site has coverage=0.83, capacity=0.75, throughput=0.99, composite = (0.83+0.75+0.99)/3 = 85.7%). Use site name map for display.

### Step 3 — Select site(s) to drill into

- If user named a site → resolve its site_id.
- If not specified → drill into the worst-ranked site automatically.
- If multiple sites are red (< 80%) → drill into all of them.

### Step 4 — Get enabled metrics for the site

```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  params={"query_type": "metrics", "scope": "site", "scope_id": "<site_id>"}
)
```

Returns `{"enabled": [...], "supported": [...]}`. Only proceed with metrics in `enabled` that belong to the current domain. Prefer versioned metrics (e.g., `switch-health-v2` over `switch-health`, `wan-link-health-v2` over `wan-link-health`).

### Step 5 — Per-metric summary and classifiers

For each enabled metric (skip if score >= 95% unless user asked for full breakdown):

```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "summary",
    "scope": "site",
    "scope_id": "<site_id>",
    "metric": "<metric_name>"
  }
)
```

Extract:
- `data.impact.num_users` / `total_users` → % users/clients impacted
- `data.impact.num_aps` / `total_aps` → % entities impacted (APs, switches, or gateways depending on domain — the field name is always `num_aps`/`total_aps` regardless of domain)
- `data.classifiers[]` → each with `name`, `impact.num_users`, `impact.num_aps`

Compute classifier contribution: `classifier.impact.num_users / metric.impact.total_users * 100`.

### Step 6 — Impacted entities (for metrics < 90%)

The query_type depends on the domain:

| Domain | Entity query | Client query |
|---|---|---|
| Wireless | `impacted_aps` | `impacted_wireless_clients` |
| Wired | `impacted_switches` | `impacted_wired_clients` |
| WAN | `impacted_gateways` | `impacted_interfaces` |

```
get_mist_insights(
  insight_type="sle",
  site_id=...,
  duration="1d",
  params={
    "query_type": "<entity_query>",
    "scope": "site",
    "scope_id": "<site_id>",
    "metric": "<metric_name>"
  }
)
```

Returns array: `{mac|name, degraded, total}` per entity.
Compute per-entity SLE%: `(1 - degraded/total) * 100`. Rank worst-first, show top 5.

For "list APs/switches with SLE below X%": paginate fully and filter entities where computed SLE% < threshold.

### Step 7 — Org-wide entity ranking (optional)

If user asks "list all APs in the org with coverage SLE < 40%":
1. Get the org scorecard (Step 2) to find all sites with data.
2. For each site, run Step 6 with `impacted_aps` and the requested metric.
3. Aggregate all entities across sites. Filter by threshold.
4. Present with site name for context.

## WAN-specific notes

- `wan-link-health-v2 = 0` often means "no WAN paths monitored" — not an outage. Cross-check with v1 and `gateway-health`.
- `gateway-health = 0` usually means the gateway is offline.
- Use `impacted_interfaces` for per-interface breakdown on WAN link metrics.

## Output

Use canvas (`web-artifacts-builder`) for multi-metric dashboards with score rings, classifier bars, and entity tables. The dashboard should use CSS variables for theming (see `web-artifacts-builder` skill). Use markdown for simple single-metric answers.

After any visual dashboard, write a brief prose summary (2-4 sentences) covering only the critical issues and recommended actions. Don't repeat what the dashboard shows.

## Error handling

| Situation | Action |
|---|---|
| Site has no SLE data | Skip, note "No [domain] SLE data — no devices or unlicensed" |
| Metric not in enabled list | Skip — not enabled for this site |
| summary returns 400 | Try `duration="7d"` — short windows sometimes have no data |
| impacted_* returns empty | Note "No entity-level breakdown available" |
| Site name not found | Use `search_mist_data(search_type='sites', filters={name: '...'})` |
