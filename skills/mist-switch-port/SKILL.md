---
name: mist-switch-port
description: >
  Use when the user asks about switch ports, port status, port speed, switch stacks,
  port profiles, MAC auth, DNS servers on switches, inactive ports, devices connected
  to a switch, APs at 100Mbps, PoE power draw, or switchport config comparison.
  Triggers on phrases like "active ports", "100Mb ports", "switch stack", "port profiles",
  "mac auth", "DNS servers on switches", "inactive ports", "devices on switch",
  "switchport config comparison", "overrides on switches", "PoE draw", "power usage".
---

# Mist Switch & Port Operations

Inspect switch ports, compare configs, map stacks to connected APs, find port speeds, profiles, PoE usage, and DNS settings across Mist-managed switches.

## Workflow

### Step 0 — Resolve org_id and sites

1. `get_mist_self` → `org_id`.
2. If user names a site, resolve it by name: `search_mist_data(scope='org', search_type='sites', org_id=..., filters={name:'<site_name>'})` → `site_id`. Only fetch the full site list (`get_mist_config(resource_type='sites', scope='org', org_id=..., limit=200)`) when you need a complete site map (e.g., org-wide queries).
3. If a specific switch is named, resolve it: `find_mist_entity(org_id=..., query='<switch_name>', entity_types=['device'])`.

### Step 1 — Route by question type

| User intent | Go to |
|---|---|
| Switchport config comparison (working vs non-working AP) | Step 2 |
| Switch stacks with connected APs | Step 3 |
| Active / inactive ports at a site | Step 4 |
| Ports at 100Mb / APs at 100Mbps | Step 5 |
| PoE power draw | Step 5b |
| Switch overrides | Step 6 |
| DNS servers on switches | Step 7 |
| MAC auth enabled ports | Step 8 |
| Port profiles at a site | Step 9 |
| Devices connected to a specific switch | Step 10 |

### Step 2 — Switchport config comparison

Goal: compare the port config for the ports where a working AP and a non-working AP are connected.

1. Resolve both APs by name/MAC: `find_mist_entity(org_id=..., query='<ap_name>')`.
2. Find which switch ports they connect to: `get_mist_stats(stats_type='site_ports', site_id=..., limit=100)`. Paginate. Look for ports where `neighbor_system_name` matches the AP hostname.
3. Note the switch MAC (`mac` field) and `port_id` for each AP.
4. Get the switch device config: `get_mist_config(resource_type='devices', scope='site', site_id=..., resource_id='<switch_device_id>')`.
5. Compare the `port_config` entries for the two port_ids. Highlight any differences (VLAN, PoE, profile, speed settings).

### Step 3 — Switch stacks with connected APs

1. Get port stats: `get_mist_stats(stats_type='site_ports', site_id=..., limit=100)`. Paginate fully.
2. **Detect virtual chassis**: ports with `vcp-` prefix (e.g., `vcp-0/1/3`, `vcp-1/1/3`) are virtual chassis inter-member links. Multiple `vcp-` ports sharing the same `mac` = a stack. The FPC number in `ge-X/0/Y` identifies the stack member.
3. Filter user-facing ports only (exclude internal ports — see Port field reference below).
4. Identify AP connections: ports where `neighbor_system_name` is set and matches AP hostnames. Cross-reference with `get_mist_stats(stats_type='site_devices', site_id=...)` to classify neighbors as APs.
5. Present: stack name | member switches (by FPC number) | connected APs (with port, speed, PoE status) | disconnected APs (with last_seen from device stats).

### Step 4 — Active / inactive ports

1. Get port stats: `get_mist_stats(stats_type='site_ports', site_id=..., limit=100)`. Paginate fully.
2. For a specific switch, filter by `mac` (switch MAC). For all switches at site, include all.
3. Filter out internal ports (see Port field reference below).
4. **Active ports:** `up=true` (link up). **Inactive:** `up=false`.
5. The `active` field indicates recent traffic — `up=true` but `active=false` means link is up but no traffic.
6. Present: switch name | port_id | up | active | speed | duplex | neighbor | poe_on | power_draw.

### Step 5 — Ports at 100Mb / APs at 100Mbps

1. Get port stats. If no site specified, use org-level: `get_mist_stats(stats_type='org_ports', org_id=..., limit=100)`. For a specific site: `get_mist_stats(stats_type='site_ports', site_id=..., limit=100)`. Paginate fully.
2. Filter where `speed=100` and `up=true`. Exclude internal ports.
3. Build AP hostname list: `get_mist_stats(stats_type='org_devices', org_id=..., filters={type:'ap'})`. Collect all AP hostnames.
4. Cross-reference each port's `neighbor_system_name` against the AP hostname list. Mark as "AP" if matched, "other" otherwise.
5. Present: switch | port_id | speed | neighbor device | type (AP/other).

### Step 5b — PoE power draw

1. Get port stats (site or org level). Paginate fully.
2. Filter ports where `poe_on=true`. These ports have a `power_draw` field (in watts).
3. Summarize: total PoE draw per switch, per-port breakdown.
4. Present: switch | port_id | neighbor | speed | power_draw (W).

### Step 6 — Switch overrides

Overrides are device-level configurations that differ from the assigned template/profile.

1. Get switch configs: `get_mist_config(resource_type='devices', scope='site', site_id=...)`. Filter `type='switch'`.
2. For each switch, look for fields that override the template: `port_config`, `ip_config`, `dns_servers`, `additional_config_cmds`, `networks`, `port_mirroring`, `ntp_servers`, `mist_nac`, etc.
3. Any non-empty field on the device config that would normally come from the device profile is an override.
4. Present: switch name | overridden fields | values.

### Step 7 — DNS servers on switches

1. Get all switch configs: `get_mist_config(resource_type='devices', scope='site', site_id=...)` or org-wide.
2. Extract `dns_servers` field from each switch config. Also check `ip_config.dns` and `oob_ip_config.dns`.
3. Group switches by DNS server set.
4. Present: DNS servers | switches using them.

### Step 8 — MAC auth enabled ports

1. Get switch configs at site: `get_mist_config(resource_type='devices', scope='site', site_id=...)`.
2. For each switch, inspect `port_config`. Look for ports where `port_auth.type` is `"dot1x"` or `"mac_auth"`, or `port_auth.enable_mac_auth` is true.
3. Present: switch | port_id | auth type | profile/usage.

### Step 9 — Port profiles at site

1. Get switch configs at site. Inspect `port_config` for each switch.
2. Each port entry has a `usage` field (e.g., "ap", "default", "uplink", custom names).
3. Also check `get_mist_config(resource_type='deviceprofiles', scope='org', org_id=...)` for org-level port profile definitions.
4. Present: profile name/usage | port count | description/settings.

### Step 10 — Devices connected to a switch

1. Resolve the switch: `find_mist_entity(org_id=..., query='<switch_name>')`.
2. Get its port stats: `get_mist_stats(stats_type='site_ports', site_id=..., filters={mac:'<switch_mac>'}, limit=100)`. Paginate.
3. Filter out internal ports. Extract `neighbor_system_name` and `neighbor_port_desc` from each port.
4. Cross-reference with device inventory to classify neighbors (AP, switch, gateway, unknown).
5. Present: port_id | neighbor name | neighbor type | speed | poe_on | power_draw | rx_bps/tx_bps.

## Port field reference

Fields returned by `site_ports` / `org_ports` stats:

| Field | Description |
|---|---|
| `mac` | Switch MAC address |
| `port_id` | Port name (e.g., `ge-0/0/1`, `mge-0/0/0`, `xe-0/2/0`) |
| `up` | Link state: true = up, false = down |
| `active` | Recent traffic detected (up + no traffic = `active=false`) |
| `speed` | Link speed in Mbps: 100, 1000, 2500, 5000, 10000 |
| `full_duplex` | true/false |
| `poe_on` | PoE enabled on this port |
| `power_draw` | PoE power draw in watts (only present when `poe_on=true`) |
| `neighbor_system_name` | LLDP neighbor hostname (only present if LLDP neighbor detected) |
| `neighbor_port_desc` | LLDP neighbor port description |
| `rx_bps` / `tx_bps` | Current throughput in bits per second |
| `rx_bytes` / `tx_bytes` | Total bytes transferred |

**Port type prefixes:**

| Prefix | Meaning |
|---|---|
| `ge-` | Gigabit Ethernet (1G copper) |
| `mge-` | Multi-Gig Ethernet (2.5G/5G/10G copper) |
| `xe-` | 10 Gigabit Ethernet (SFP+) |
| `et-` | 25G/40G/100G Ethernet |
| `vcp-` | Virtual Chassis Port (inter-member link) |

**Internal ports to exclude from user-facing queries:** `bme0`, `cbp0`, `irb`, `jsrv`, `pip0`, `vme`, `me0`, `inband-management`. These are system/management interfaces — filter them out unless specifically asked.

## Pagination

Port stats can be large (646+ ports in an org). Always paginate `has_more` → `next_cursor`.

## Output

Use canvas for port grid visualizations or stack topology diagrams when data is substantial. Markdown tables for focused queries.

## Error handling

| Situation | Action |
|---|---|
| Switch not found | Try `search_mist_data(search_type='devices', filters={hostname:'...'})` |
| No port stats | Switch may be disconnected — check device status first |
| Port has no neighbor info | LLDP not enabled or no device connected on that port |
| Virtual chassis not detected | Look for `vcp-` ports in port stats (definitive signal) |
