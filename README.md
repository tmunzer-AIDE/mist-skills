# Mist AI MCP Skills

Agent skills for the [Mist AI MCP server](https://github.com/tmunzer/mist-mcp), enabling Claude (and other LLM agents) to answer networking questions using live data from the Juniper Mist Cloud.

Each skill follows the [agentskills.io](https://agentskills.io/specification) specification: a `SKILL.md` file with YAML frontmatter for triggering, and optional `references/` for heavy content.

## Compatible AI Applications

These skills use the open [Agent Skills](https://agentskills.io/) standard and work with multiple AI desktop applications:

| Application | Skill Location |
|-------------|----------------|
| **Claude Desktop** | `~/.claude/skills/` |
| **Goose** (Block) | `~/.goose/skills/` |
| **TRAE** | `~/.trae/skills/` |
| **Gemini CLI** | `~/.agents/skills/` |
| **GH Copilot** | `~/.copilot/skills/` |

See the full list of compatible tools at [agentskills.io](https://agentskills.io/).

## Skills

| Skill | Description | Lines |
|---|---|---|
| [mist-sle](mist-sle/SKILL.md) | SLE analysis for wireless, wired, and WAN: org-level site ranking, site drill-down, classifier breakdown, impacted entities | 170 |
| [mist-device-inventory](mist-device-inventory/SKILL.md) | Device inventory queries: Wi-Fi 7/6E/6 AP detection, firmware audit, vendor filtering, power draw, license checks | 108 |
| [mist-client-analysis](mist-client-analysis/SKILL.md) | Client usage and bandwidth: app usage, traffic ranking, 6 GHz clients, roaming detection, manufacturer filtering | 134 |
| [mist-client-troubleshoot](mist-client-troubleshoot/SKILL.md) | Client diagnostics: Marvis AI root cause analysis, session pattern detection, NAC event correlation | 136 |
| [mist-network-issues](mist-network-issues/SKILL.md) | Alarms, events, and Marvis actions: AP offline/reboot, switch problems, bad cables, rogue APs, NAC failures | 135 |
| [mist-network-config](mist-network-config/SKILL.md) | Configuration inspection: DHCP, RF templates, 802.11r, auth server timeouts, WLAN changes, config diff | 134 |
| [mist-switch-port](mist-switch-port/SKILL.md) | Switch port operations: port status, 100 Mbps detection, stack mapping, port profiles, config comparison | 127 |

## MCP Tools Used

All skills interact with the Mist Cloud through 7 MCP tools:

| Tool | Purpose |
|---|---|
| `get_mist_self` | Discover org_id from the authenticated session |
| `find_mist_entity` | Search for any entity (client, device, mxedge) by MAC or name |
| `get_mist_config` | Read configuration objects (sites, WLANs, RF templates, devices, etc.) |
| `get_mist_constants` | Discover available event types, insight metrics, alarm definitions |
| `get_mist_insights` | AI analytics: SLE scores, Marvis actions, troubleshoot, insight metrics |
| `get_mist_stats` | Current-state statistics: devices, ports, wireless clients, sites |
| `search_mist_data` | Historical search: events, alarms, client sessions, rogue events |

## Project Structure

```
mistmcp_skills/
  mist-sle/
    SKILL.md
    references/
      metrics.md              # SLE metrics, classifiers, and fixes
  mist-device-inventory/
    SKILL.md
    scripts/
      classify_ap_models.py    # Classifies AP models by Wi-Fi standard
  mist-client-analysis/
    SKILL.md
  mist-client-troubleshoot/
    SKILL.md
  mist-network-issues/
    SKILL.md
    references/
      event-types.md           # Alarm, device event, NAC event types
  mist-network-config/
    SKILL.md
  mist-switch-port/
    SKILL.md
```

## Installation

Copy the skill directories into your agent's skill path:

**Claude Code:**
```bash
cp -r mist-* ~/.claude/skills/
```

**Custom agent (Claude Agent SDK):**
Point your agent's skill loader at this directory, or copy individual skill folders into your agent's configured skill path.

## Key Design Decisions

- **Site resolution**: Skills use `search_mist_data(search_type='sites', filters={name:'...'})` to resolve a site by name directly, avoiding a full site list fetch. The full list is only fetched for org-wide queries that need a complete name map.
- **Pagination**: All list/search calls may return partial results. Skills instruct to check `has_more` and use `next_cursor`.
- **Versioned metrics**: Skills prefer versioned API endpoints (`switch-health-v2`, `wan-link-health-v2`) over their non-versioned equivalents.
- **Progressive disclosure**: Heavy reference content (Wi-Fi model tables, event type catalogs, SLE classifier guides) lives in `references/` and is loaded only when needed.
- **API constraints**: `rogue_events` requires `scope='site'` (no org-wide query). `wireless_client_events` does not support MAC filtering (use `client_sessions` instead).

## License

Apache 2.0 — see [LICENSE](LICENSE)
