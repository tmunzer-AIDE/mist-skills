---
name: mist-network-config
description: >
  Use when the user asks about network or WLAN configuration: DHCP servers,
  DHCP bindings, RF templates, 802.11r settings, authentication server timeouts,
  bonjour gateway, recent config changes, WLAN changes, or config diffs.
  Triggers on phrases like "DHCP servers", "RF configuration", "802.11r",
  "fast roaming", "auth server timeout", "bonjour gateway", "config changes",
  "WLANs changed", "config diff", "WLAN settings", "RADIUS timeout",
  "show WLANs with feature X". Use for any configuration inspection question.
---

# Mist Network & WLAN Configuration

Inspect DHCP, RF templates, WLAN features, authentication server settings, bonjour gateway, and track configuration changes across the Mist network.

## Workflow

### Step 0 — Resolve org_id and sites

1. `get_mist_self` → `org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. Only fetch the full site list (`get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`) when you need a complete site map (e.g., org-wide queries).

### Step 1 — Route by question type

| User intent | Go to |
|---|---|
| DHCP servers on a network/site | Step 2 |
| DHCP bindings | Step 3 |
| RF configuration at a site | Step 4 |
| WLANs with specific feature (802.11r, etc) | Step 5 |
| Auth server timeout settings | Step 6 |
| Bonjour gateway config | Step 7 |
| Recent config changes at a site | Step 8 |
| WLANs changed/added/removed recently | Step 9 |
| Config diff (today vs last week) | Step 10 |

### Step 2 — DHCP servers

DHCP config can live in multiple places:

1. **Networks:** `get_mist_config(resource_type='networks', scope='org', org_id=..., limit=100)`. Paginate. Look for `dhcp` field with server settings, `dhcpd_config`, or `gateway` fields.
2. **Device configs (switches/gateways):** `get_mist_config(resource_type='devices', scope='site', site_id=...)`. Look for `dhcp_config`, `dhcpd_config`, or `ip_config` fields referencing DHCP relay.
3. **WLANs:** Some WLANs may have DHCP relay settings.
4. Aggregate all DHCP sources. Present: source (network/device/WLAN) | DHCP server IPs | network/VLAN.

### Step 3 — DHCP bindings

The Mist API does not expose live DHCP binding tables directly. Workaround:

1. Search for DHCP-related events: `search_mist_data(scope='site', search_type='device_events', site_id=..., duration='1d')`. Filter `text` containing "DHCP" if possible.
2. Alternatively, check client data — `search_mist_data(search_type='wireless_clients')` shows `ip` and `vlan` which reflect DHCP assignments.
3. Report the limitation: "Live DHCP bindings are not directly available via the API. Showing DHCP-assigned client IPs instead."

### Step 4 — RF configuration

1. Get the site config to find the assigned RF template: `get_mist_config(resource_type='sites', scope='org', org_id=..., resource_id='<site_id>')`. Look for `rftemplate_id`.
2. Fetch the full RF template: `get_mist_config(resource_type='rftemplates', scope='org', org_id=..., resource_id='<rftemplate_id>')`.
3. Extract band settings: `band_24` (power, channels, bandwidth), `band_5` (power, channels, bandwidth, DFS), `band_6` (power, channels, bandwidth).
4. Also check for site-level RF overrides in the site config.
5. Present: band | power range | channels | bandwidth | DFS | other settings.

Note: listing RF templates returns minimal fields. You must fetch with `resource_id` for full details.

### Step 5 — WLANs with specific features

1. Get all WLANs:
   - Org-level: `get_mist_config(resource_type='wlans', scope='org', org_id=..., limit=100)`. Paginate.
   - Site-level: only query if user specified a site or if org-level returned no matches. Iterate specific sites, not all sites in large orgs.
2. Filter by the requested feature:
   - **802.11r:** `roam_mode == "11r"` or `fast_dot1x_roaming == true` (these are independent — `roam_mode` sets the roaming protocol, `fast_dot1x_roaming` enables OKC; either indicates fast roaming is configured)
   - **Bands:** check `bands` array (e.g., ["24","5","6"])
   - **Auth type:** check `auth.type` ("psk", "eap", "open")
   - **Multi-PSK:** `auth.multi_psk_only == true`
   - **MAC auth:** `auth.enable_mac_auth == true`
   - **Tunnel to MxEdge:** `mxtunnel_id` or `mxtunnel_ids` is set
3. Present: SSID | feature value | bands | auth type | enabled | scope (org/site).

### Step 6 — Auth server timeout settings

1. Get WLANs (org + site level as in Step 5).
2. For each WLAN with `auth.type == "eap"`, look for `auth_servers` and `acct_servers` arrays.
3. Each server entry contains: `host`, `port`, `secret` (masked), `timeout`, `retries`.
4. Also check `radsec` settings if present.
5. Present: SSID | server host | port | timeout | retries.

### Step 7 — Bonjour gateway

Bonjour gateway config can be at multiple levels:

1. **WLAN level:** check `bonjour` field in WLAN configs.
2. **Site level:** `get_mist_config(resource_type='sites', scope='org', resource_id='<site_id>')` — look for `bonjour` or `mdns` settings.
3. **Network level:** check network configs for mDNS/bonjour relay settings.
4. **Device level:** check switch/gateway configs for bonjour proxy settings.
5. Report what's configured and at which level.

### Step 8 — Recent config changes

1. Search device events at the site: `search_mist_data(scope='site', search_type='device_events', site_id=..., duration='24h', limit=100)`. Paginate.
2. Filter for config change events: types containing "CONFIG_CHANGED" — specifically `AP_CONFIG_CHANGED`, `SW_CONFIG_CHANGED`, `GW_CONFIG_CHANGED`.
3. Extract: timestamp, device name (from MAC), device_type, text (change description).
4. Present chronologically: time | device | type | description.

### Step 9 — WLAN changes in time range

1. Get all WLANs (org + site level).
2. Filter by `modified_time`: compare against the requested time range. For "last 24h": `current_epoch - 86400`.
3. WLANs with `modified_time` in range were recently changed.
4. For removals: search device events for WLAN-related changes, or note that deletions aren't directly trackable.
5. Present: SSID | last modified | scope | change type (modified/new).

### Step 10 — Config diff

**Limitation:** The Mist API does not store historical config snapshots. A true config diff is not possible.

Workaround:
1. Get current config for the site/devices.
2. Search device events for config changes over both time ranges (today and last week).
3. List all config change events to show what was modified.
4. Be transparent: "Historical config snapshots are not available via the API. Showing config change events instead."

## Output

Use canvas for WLAN feature matrices or RF config visualizations when comparing multiple items. Markdown tables for focused lookups.

## Error handling

| Situation | Action |
|---|---|
| RF template ID not found on site | Site may use default RF settings — report "No RF template assigned" |
| No auth_servers on WLAN | WLAN may use PSK auth — no RADIUS servers to show |
| DHCP bindings unavailable | Report limitation, show client IP assignments instead |
| Config diff not possible | Show change event log as substitute |
| WLAN scope ambiguous | Check both org-level and site-level WLANs |
