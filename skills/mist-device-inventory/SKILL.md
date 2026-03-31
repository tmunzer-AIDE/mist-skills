---
name: mist-device-inventory
description: >
  Use when the user asks about device inventory, firmware versions, AP models,
  Wi-Fi standards (Wi-Fi 7, 6E, 6GHz), hardware capabilities, switch compatibility,
  license expiry, power draw, or Mist Edge tunneling. Triggers on questions like
  "what APs do I have", "firmware versions", "Wi-Fi 7 APs", "6GHz capable",
  "outdated firmware", "cisco switches in my org", "expired licenses",
  "APs tunneled to Mist Edge". Use this even when the user just wants device counts
  or connected/disconnected status breakdowns.
---

# Mist Device Inventory & Firmware Analyser

Enumerate devices, audit firmware, classify Wi-Fi capabilities, and detect hardware features across the Mist org using live inventory data.

## Workflow

### Step 0 — Resolve org_id and sites

1. Call `get_mist_self` once to get `org_id` from `privileges[0].org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. Only fetch the full site list (`get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`) when you need a complete site map (e.g., org-wide inventory queries).

### Step 1 — Route by question type

| User intent | Go to |
|---|---|
| Wi-Fi 7 / 6GHz / 6E APs, GPS APs | Step 2 |
| Firmware versions, outdated firmware, recommended firmware | Step 3 |
| Cisco switches / non-Juniper devices | Step 4 |
| Power draw stats | Step 5 |
| License expiry | Step 6 |
| APs tunneled to Mist Edge | Step 7 |
| General inventory overview | Step 3 (full inventory) |

### Step 2 — Wi-Fi capability queries

Read [references/wifi-models.md](references/wifi-models.md) for the capability-to-model mapping. The MCP does not expose this — you must use the embedded tables.

1. Get all APs: `search_mist_data(scope='org', search_type='inventory', org_id=..., filters={device_type:'ap'}, limit=100)`. Paginate fully.
2. For each AP, match `model` against the reference tables to classify its Wi-Fi standard.
3. Filter to the requested capability (Wi-Fi 7, 6GHz, GPS, etc).
4. Present results grouped by site with model, name, status, and firmware.

### Step 3 — Firmware audit

1. Get all devices of the requested type (ap/switch/gateway): `search_mist_data(scope='org', search_type='inventory', org_id=..., filters={device_type:'ap'}, limit=100)`. Paginate fully.
2. Group by `model`, then by `version` within each model.
3. **Recommended firmware heuristic:** the most common version per model is likely the recommended one. Flag devices on older versions.
4. **Version comparison:** parse `version` as `major.minor.patch` (e.g., "0.14.29583" → major=0, minor=14). Compare numerically. "0.14.x" < "0.15.x".
5. For "running X or below" queries: filter where minor <= requested version number.
6. Present: model | current version | count | status (current/outdated).

### Step 4 — Vendor / compatibility queries

Mist inventory only contains Juniper/Mist devices. Non-Juniper hardware (Cisco, Aruba) will never appear in the inventory.

1. Search inventory: `search_mist_data(scope='org', search_type='inventory', org_id=..., limit=100)`. Paginate.
2. Check all `model` values — all will be Juniper models (AP*, EX*, QFX*, SRX*, SSR*, etc).
3. If user asks "are there Cisco switches": report "No — Mist inventory only contains Juniper/Mist-managed devices."
4. If user asks "can I put [model] in Mist": check against `get_mist_constants(constant_type='device_models')`. If the model appears, it's compatible.

### Step 5 — Power draw stats

1. Resolve the site if specified.
2. Call `get_mist_stats(stats_type='site_devices', site_id=...)` to get per-device stats.
3. The stats may include power-related fields (`lldp_stat.power_draw`, `env_stat`). If not available at summary level, note the limitation and suggest checking the Mist dashboard.
4. Present: AP name | model | status | IP | uptime | power info (if available).

### Step 6 — License expiry

The MCP does not expose license expiry dates directly. Approach:

1. Call `get_mist_self` — check if org privileges include license info.
2. If not available, report the limitation: "License expiry data is not accessible via the API. Check Organization > Subscriptions in the Mist dashboard."

### Step 7 — Mist Edge tunnel detection

1. Get all org-level WLANs: `get_mist_config(resource_type='wlans', scope='org', org_id=..., limit=100)`. Paginate.
2. Also get site-level WLANs for each relevant site.
3. Filter WLANs where `mxtunnel_id` or `mxtunnel_ids` is set — these tunnel to Mist Edge.
4. Identify which sites those WLANs are deployed to (via `template_id` → site assignment, or site_id).
5. Get APs at those sites: `search_mist_data(scope='org', search_type='inventory', filters={device_type:'ap', site_id:...})`.
6. Present: WLAN name | tunnel target | site | APs serving it.

## Pagination

All `search_mist_data` and `get_mist_config` calls may return partial results. Always check `has_more` — if true, call again with `next_cursor` until all data is retrieved. This is critical for orgs with many devices.

## Output

Present results as clean tables. For large datasets, use canvas (`web-artifacts-builder` skill) to render an interactive dashboard with:
- Summary cards (total APs, switches, gateways; connected vs disconnected)
- Firmware distribution grouped by model
- Wi-Fi standard badges per device
- Flagged outliers highlighted

For smaller results, a markdown table is fine.

## Error handling

| Situation | Action |
|---|---|
| Site name not found | Use `search_mist_data(search_type='sites', filters={name:'...'})` to fuzzy-match |
| No devices returned | Report "No devices of type X found in the org/site" |
| Unknown model not in reference table | Report the model as "Unknown Wi-Fi standard" and show raw model string |
| License data unavailable | Direct user to Mist dashboard |
| Pagination incomplete | Always paginate — partial data leads to wrong conclusions |
