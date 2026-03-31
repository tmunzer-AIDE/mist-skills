---
name: mist-client-troubleshoot
description: >
  Expert Mist AI-powered client troubleshooting workflow. Use this skill whenever
  someone reports a user connectivity issue, asks why a device can't connect, says
  "troubleshoot client", "user can't reach wifi", "X is having network problems",
  mentions a MAC address in the context of a problem, or asks you to investigate
  a specific wireless/wired/WAN client. Also triggers for "find user on network",
  "which AP is [user] on", "what's [hostname] doing", or any complaint about a
  specific device's connectivity. Always use this skill when a MAC address or
  client hostname appears alongside words like: issue, problem, can't, doesn't
  work, troubleshoot, investigate, slow, disconnected, failing, authentication.
license: Apache-2.0
metadata:
  author: thomas.munzer@hpe.com
  version: "1.0"
---
 
# Mist Client Troubleshooter
 
A structured Marvis AI-powered workflow for diagnosing and explaining client connectivity issues on the Mist platform.
 
## When to use this skill
 
Use whenever a user:
- Reports a client/user connectivity problem
- Gives you a MAC address or hostname to investigate
- Asks why a device can't connect to WiFi, the wired network, or WAN
- Asks which AP or SSID a client is on
- Wants to know the recent history of a specific device
 
---
 
## Step-by-step workflow
 
### Step 0 — Discover org_id
 
Call `get_mist_self` **once per session** to get the org_id. Reuse it for all subsequent calls. Skip if already known from context.
 
---
 
### Step 1 — Identify the client
 
Extract the identifier from the user's message:
- **MAC address**: any notation (`aa:bb:cc`, `AA-BB-CC-DD-EE-FF`, `aabbccddeeff`)
- **Hostname / username**: partial match is fine, `find_mist_entity` will prefix-wildcard it
 
Call `find_mist_entity` with the identifier:
```
find_mist_entity(org_id=..., query="<mac_or_hostname>")
```
 
If **not found**: tell the user clearly ("No client matching `<query>` found in the org") and stop.
 
If **multiple results**: list them briefly and ask the user to confirm which one.
 
If **found**: note the `entity_type`, `mac`, `site_id`, `site_name`, and `name`. Proceed.
 
---
 
### Step 2 — Get Marvis AI root cause analysis
 
Call `get_mist_insights` with `insight_type=troubleshoot`:
```
get_mist_insights(
  insight_type="troubleshoot",
  org_id=...,
  site_id=<site_id from Step 1>,  # use site_id for site-level context
  duration="7d",
  params={"mac": "<compact_mac>", "type": "wireless"}  # or "wired" / "wan"
)
```
 
> **Type selection**: default to `wireless` unless the entity_type from Step 1 was `wired_client` or `wan_client`. For `wired_client` use `type=wired`. For `wan_client` use `type=wan`.
 
> **Note**: Marvis troubleshoot requires a Marvis license. If you get a 403 or license error, skip this step and note it in the output.
 
---
 
### Step 3 — Fetch recent client session history
 
> ⚠️ `wireless_client_events` does NOT support MAC filtering. Use `client_sessions` instead — it returns full connect/disconnect records per client and does support MAC filtering.
 
```
search_mist_data(
  scope="org",
  search_type="client_sessions",
  org_id=...,
  site_id=<site_id>,
  filters={"mac": "<compact_mac>"},
  duration="7d",
  limit=25
)
```
 
Key fields to extract from each session record:
- `connect` / `disconnect` (epoch timestamps → convert to human time)
- `duration` (seconds → flag anything < 10s as a **failed/flapping session**)
- `ap` (AP MAC)
- `ssid`
- `tags` (e.g. `disassociate`, `auth_fail`)
- `client_ip` (changes between sessions = DHCP churn pattern)
 
**Pattern recognition:**
- Many short sessions (< 10s) = repeated auth/association failures
- Regular ~4h sessions = possibly DHCP lease timeout or 802.1X re-auth timer
- Changing IPs every session = DHCP scope issues or client roaming aggressively
 
If the Marvis output (Step 2) suggests auth/NAC failures, **also** call:
```
search_mist_data(
  scope="org",
  search_type="nac_client_events",
  org_id=...,
  filters={"mac": "<compact_mac>"},
  duration="24h",
  limit=25
)
```
NAC events DO support MAC filtering and give RADIUS/802.1X detail.
 
---
 
### Step 4 — Get current session details (if client is connected)
 
If Step 1 returned `entity_type=wireless_client` (meaning the client is currently connected), get live session details:
```
get_mist_stats(
  stats_type="site_wireless_clients",
  site_id=<site_id>,
  object_id=<compact_mac>
)
```
 
This gives RSSI, SNR, band, AP association, IP address, and throughput — useful for "connected but slow" cases.
 
---
 
### Step 5 — Format the output
 
Present the findings as a structured diagnostic report:
 
```
## 🔍 Client Diagnosis: <name or MAC>
 
**Identity**
- MAC: <mac>
- Hostname: <hostname if known>
- Site: <site_name>
- Entity type: <wireless_client / wired_client / etc.>
 
**Current Status**
- Status: Connected / Not found in current sessions
- AP: <AP name and MAC> (if connected)
- SSID: <ssid> (if wireless)
- Band: <2.4/5/6 GHz>
- RSSI: <value> dBm | SNR: <value> dB
- IP: <ip address>
 
**🤖 Marvis AI Analysis**
<Summarize Marvis findings — root cause, confidence, recommended action>
 
**📋 Session History (last 7d)**
Show as a timeline, most recent first. Flag anomalies:
  YYYY-MM-DD HH:MM — Connected → Disconnected (duration: Xh Ym) [AP name] [SSID]
  YYYY-MM-DD HH:MM — ⚠️ Flash session (0.9s) — likely failed auth [AP name]
  ...
Note patterns: "16 sessions in 7d, all ~4h duration → possible DHCP/re-auth timer"
 
**✅ Recommended Actions**
1. <Action based on Marvis + event evidence>
2. <...>
```
 
#### Interpretation guidance
 
| Marvis finding | Likely action |
|---|---|
| `DHCP failure` | Check DHCP scope exhaustion, port config, VLAN tagging |
| `DNS failure` | Verify DNS server reachability, check gateway config |
| `Auth failure` / 802.1X | Check RADIUS server, certificate, NAC policy |
| `Missing VLAN` | Verify VLAN exists on switch port / wired uplink |
| `Bad cable` | Physical inspection, replace cable |
| `Low RSSI` | Check AP coverage, client moving to wrong AP, consider band steering |
| `Roaming issues` | Check 802.11r/k/v config, AP neighbor lists |
| No Marvis result | Rely on event timeline; note Marvis may need more data |
 
---
 
## Output principles
 
- Lead with the most actionable finding — don't bury Marvis's verdict
- If the client is **not connected**, focus on recent failure events and last-seen time
- If events show a **recurring pattern** (e.g., auth failures every 30 min), highlight it explicitly
- Keep event timeline concise — top 10 events max; summarize patterns rather than listing every line
- If Marvis gives a specific recommendation, quote it directly
- Avoid overwhelming with raw JSON — extract the meaningful fields only
 
---
 
## Error handling
 
| Situation | Response |
|---|---|
| Client not found | "No client matching `<query>` was found. Check the MAC/hostname and try again." |
| Marvis license error | Skip Step 2, note "Marvis AI not available — check license". Proceed with events. |
| Site ID unknown | Use `get_mist_config(resource_type='sites', scope='org', org_id=...)` to look up site by name |
| Multiple matching clients | List them, ask user to clarify |
