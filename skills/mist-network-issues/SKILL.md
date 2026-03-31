---
name: mist-network-issues
description: >
  Use when the user asks about network problems, alarms, device events, Marvis
  actions, AP offline/reboot reasons, switch issues, PoE problems, bad cables,
  ethernet errors, CPU utilization, rogue APs, NAC auth failures, Teams call
  quality, event trends, or general "what's wrong with my network" questions.
  Triggers on phrases like "alarms", "marvis actions", "APs offline", "AP reboot",
  "switches with problems", "poe issues", "bad cables", "rogue AP",
  "NAC failures", "auth failures", "Teams calls", "switching issues",
  "high CPU", "ethernet errors", "event trend".
---

# Mist Network Issues, Alarms & Marvis

Investigate active alarms, device events, Marvis AI actions, rogue APs, NAC failures, and call quality issues across the Mist network.

## Workflow

### Step 0 — Resolve org_id and sites

1. `get_mist_self` → `org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. Only fetch the full site list (`get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`) when you need a complete site map (e.g., org-wide queries).

For event type discovery, see [references/event-types.md](references/event-types.md).

### Step 1 — Route by question type

| User intent | Go to |
|---|---|
| Active alarms (PoE, system, chassis, any type) | Step 2 |
| AP offline / AP reboot reasons | Step 3 |
| Switch problems / switching issues | Step 4 |
| Bad cables / ethernet errors | Step 5 |
| High CPU utilization | Step 6 |
| Rogue AP detection | Step 7 |
| Marvis actions (all, or filtered) | Step 8 |
| Teams call quality / path issues | Step 9 |
| NAC / auth failures and trends | Step 10 |
| Event trends (wireless client events, etc) | Step 11 |

### Step 2 — Active alarms

1. `search_mist_data(scope='org', search_type='alarms', org_id=..., limit=100)`. Paginate.
2. Filter by what the user asks:
   - PoE: filter `type` containing "poe" or "power"
   - System/chassis: filter `type` containing "alarm" or check `group='infrastructure'`
   - By severity: use `filters={severity:'critical'}`
3. For each alarm, extract: type, severity, group, site_id (→ site name), impacted_entities (entity_name, entity_type), status, last_seen, count.
4. Present grouped by severity (critical first), then by type.

### Step 3 — AP offline / reboot

1. Search device events: `search_mist_data(scope='site', search_type='device_events', site_id=..., duration='24h', filters={event_type:'AP_DISCONNECTED'}, limit=100)`. Paginate.
2. For reboots: also search `event_type='AP_RESTARTED'`.
3. Extract: AP name (from `mac` → cross-reference inventory), timestamp, `text` (contains reason).
4. Group by AP. Show reboot count and reasons.
5. If user asks "why": the `text` field often contains the cause (e.g., "firmware upgrade", "power cycle", "crash").

### Step 4 — Switch problems

Two approaches — combine for comprehensive results:

1. **Alarms:** `search_mist_data(scope='org', search_type='alarms', org_id=..., filters={group:'infrastructure'}, duration='7d')`. Filter where impacted_entities contain switches.
2. **Marvis:** `get_mist_insights(insight_type='marvis_actions', org_id=..., limit=100)`. Filter `category='switch'`.
3. **Events:** `search_mist_data(scope='site'|'org', search_type='device_events', duration='7d', filters={event_type:'SW_ALARM'})`.
4. Merge and deduplicate. Present: switch name | issue type | severity | duration | site | status.

### Step 5 — Bad cables / ethernet errors

1. **Marvis approach (preferred):** `get_mist_insights(insight_type='marvis_actions', org_id=..., limit=100)`. Filter `symptom='bad_cable'` or `symptom='negotiation_mismatch'`.
2. **Event approach:** `search_mist_data(search_type='device_events', duration='7d')`. Look for port flapping patterns (rapid SW_PORT_UP/SW_PORT_DOWN on same port).
3. **Port stats:** `get_mist_stats(stats_type='org_ports'|'site_ports')`. Look for ports with high error counters or speed=100 (potential negotiation issue).
4. For "which APs have ethernet errors": cross-reference port stats with AP connections via `neighbor_system_name`.

### Step 6 — High CPU utilization

1. Search events: `search_mist_data(scope='site', search_type='device_events', site_id=..., duration='7d', filters={event_type:'SW_CPU_HIGH'})`. Also try `GW_CPU_HIGH` for gateways.
2. If no specific event type works, try broader: filter `text` containing "CPU" via the `text` filter.
3. Alternatively, use Marvis: `get_mist_insights(insight_type='marvis_actions', org_id=...)` and look for CPU-related symptoms.
4. Present: device name | event timestamps | duration | text details.

### Step 7 — Rogue AP detection

**Important:** `rogue_events` requires `scope='site'` — cannot be queried org-wide.

1. Get all sites from the site map.
2. For each site (or the specific site if given): `search_mist_data(scope='site', search_type='rogue_events', site_id=..., duration='1d', limit=100)`.
3. If querying all sites, iterate and aggregate. Be mindful of rate — limit to sites the user cares about or the first batch.
4. Present: site | rogue SSID | rogue BSSID | detecting AP | channel | RSSI | timestamp.

### Step 8 — Marvis actions

1. `get_mist_insights(insight_type='marvis_actions', org_id=..., limit=100)`. Paginate if needed.
2. Filter by user request:
   - "persistently failing clients": `symptom='persistently_failing_clients'`
   - By category: `category='switch'|'gateway'|'wireless'|'wired'`
   - All: no filter
3. For each action, extract: symptom, category, severity, status, suggestion, self_driven, duration (in seconds — convert to human-readable, e.g., 86400 → "1 day"), site_id (→ name). Entity info is in `details.impacted_tuple[]`, each with fields like `mac`, `name`, `site_id`, `port_id`, `interface` depending on the entity type.
4. Present: action | affected entity | site | severity | status | suggestion | duration.

### Step 9 — Teams / call quality

1. Check Marvis for application health: `get_mist_insights(insight_type='marvis_actions', org_id=...)`. Filter for symptoms related to application health or call quality.
2. For path analysis: `get_mist_insights(insight_type='insight_metrics', site_id=..., params={object_type:'site', metric:'<call_quality_metric>'})`. Discover metrics via `get_mist_constants(constant_type='insight_metrics')`.
3. Present: call quality metrics, path analysis if available, impacted users/sites.

### Step 10 — NAC / auth failures

1. `search_mist_data(scope='org', search_type='nac_client_events', org_id=..., duration='7d', filters={type:'NAC_CLIENT_DENY'}, limit=100)`. Paginate.
2. If user specifies a WLAN: add `filters={ssid:'<wlan_name>'}`.
3. For trend analysis: group events by day. Count NAC_CLIENT_DENY per day.
4. Extract: timestamp, MAC, username, auth_type, nacrule_name, port_type, site_id.
5. Present: daily trend table/chart + top failing clients.

### Step 11 — Event trends

1. `search_mist_data(scope='org', search_type='wireless_client_events', org_id=..., duration='5d', limit=100)`. Paginate.
   - Note: `wireless_client_events` does **NOT** support MAC filter.
2. Group by event type and day.
3. Present as a trend: date | event_type | count.

## Output

Use canvas for alarm dashboards, event timelines, and trend charts when data is rich. Markdown for focused answers.

## Error handling

| Situation | Action |
|---|---|
| Rogue events need site scope | Iterate per site — never call with scope='org' |
| wireless_client_events no MAC filter | Search all events, filter in post-processing if needed |
| Marvis license required | If troubleshoot returns 403, note "Marvis license required" |
| No events found | Widen duration or report "No events of type X in the time range" |
| Unknown event type | Call `get_mist_constants(constant_type='device_events')` to discover types |
