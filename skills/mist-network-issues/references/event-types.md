# Alarm & Event Type Reference

## Alarm Types (search_mist_data search_type='alarms')

| Type | Group | Description |
|---|---|---|
| ap_down | infrastructure | AP disconnected from cloud |
| ap_restarted | infrastructure | AP rebooted |
| sw_down | infrastructure | Switch offline |
| sw_bad_cable | marvis | Bad cable detected by Marvis |
| gw_down | infrastructure | Gateway offline |
| bad_wan_uplink | marvis | WAN uplink issue |
| rogue_ap | security | Rogue AP detected |
| poe_failure | infrastructure | PoE delivery failure |
| sw_alarm | infrastructure | Switch system/chassis alarm |

Filter by: `group` (infrastructure, marvis, security), `severity` (critical, warn, info)

## Device Event Types (search_mist_data search_type='device_events')

| Type | Device | Description |
|---|---|---|
| AP_CONNECTED | AP | AP connected to cloud |
| AP_DISCONNECTED | AP | AP disconnected |
| AP_RESTARTED | AP | AP rebooted |
| AP_CONFIG_CHANGED | AP | AP config modified |
| SW_PORT_UP | Switch | Port link up |
| SW_PORT_DOWN | Switch | Port link down |
| SW_CONFIG_CHANGED | Switch | Switch config modified |
| SW_ALARM | Switch | System/chassis alarm |
| SW_DOT1XD_USR_AUTHENTICATED | Switch | 802.1X auth success |
| SW_RESTARTED | Switch | Switch rebooted |
| GW_CONFIG_CHANGED | Gateway | Gateway config modified |

Use `get_mist_constants(constant_type='device_events')` for the full list.

## NAC Event Types (search_mist_data search_type='nac_client_events')

| Type | Description |
|---|---|
| NAC_CLIENT_PERMIT | Auth success — client permitted |
| NAC_CLIENT_DENY | Auth failure — client denied |
| NAC_SESSION_STARTED | NAC session started |
| NAC_SESSION_ENDED | NAC session ended |

Use `get_mist_constants(constant_type='nac_events')` for the full list.

## Marvis Action Symptoms (get_mist_insights insight_type='marvis_actions')

| Symptom | Category | Description |
|---|---|---|
| bad_wan_link | gateway | WAN link degraded |
| sw_offline | switch | Switch offline |
| ap_offline | ap | AP offline |
| persistently_failing_clients | wireless | Clients repeatedly failing |
| bad_cable | switch | Bad cable detected |
| poe_issue | switch | PoE delivery problem |
| wireless_non_compliance | wireless | Wireless config non-compliant |
| missing_vlan | switch | VLAN not configured on port |
| dns_failure | wireless/wired | DNS resolution failing |
| dhcp_failure | wireless/wired | DHCP failure |
| negotiation_mismatch | switch | Speed/duplex mismatch |

## Key Constraints

- `rogue_events` requires scope='site' — must iterate over sites
- `wireless_client_events` does NOT support mac filter
- Severity ordering: critical > warn > info
- Status: open = active issue, resolved = fixed
