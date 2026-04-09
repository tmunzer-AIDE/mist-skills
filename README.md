# Mist AI MCP Skills

Agent skills for the [Mist AI MCP server](https://github.com/tmunzer/mist-mcp), enabling Claude (and other LLM agents) to answer networking questions using live data from the Juniper Mist Cloud.

Each skill follows the [agentskills.io](https://agentskills.io/specification) specification: a `SKILL.md` file with YAML frontmatter for triggering, and optional `references/` for heavy content.

## Compatible AI Applications

These skills use the open [Agent Skills](https://agentskills.io/) standard and work with a growing number of AI applications:

| Application | Installation |
|-------------|-------------|
| **Claude** (Web & Desktop App) | Upload `.zip` archives — see [Claude section](#claude-web--desktop-app) below |
| **Claude Code** (CLI, Desktop App, IDE) | Copy to `~/.claude/skills/` — see [Claude Code section](#claude-code--other-cli-based-apps) below |
| **Goose** (Block) | `~/.goose/skills/` |
| **Gemini CLI** | `~/.agents/skills/` |
| **Cursor** | [Cursor skills docs](https://cursor.com/docs/context/skills) |
| **GitHub Copilot** | `~/.copilot/skills/` |
| **VS Code** | [VS Code skills docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills) |
| **TRAE** | `~/.trae/skills/` |
| **Roo Code** | [Roo Code skills docs](https://docs.roocode.com/features/skills) |

See the full list of 30+ compatible tools at [agentskills.io](https://agentskills.io/).

## Skills

| Skill | Description | Lines |
|---|---|---|
| [mist-sle](skills/mist-sle/SKILL.md) | SLE analysis for wireless, wired, and WAN: org-level site ranking, site drill-down, classifier breakdown, impacted entities | 170 |
| [mist-device-inventory](skills/mist-device-inventory/SKILL.md) | Device inventory queries: Wi-Fi 7/6E/6 AP detection, firmware audit, vendor filtering, power draw, license checks | 120 |
| [mist-client-analysis](skills/mist-client-analysis/SKILL.md) | Client usage and bandwidth: app usage, traffic ranking, 6 GHz clients, roaming detection, manufacturer filtering | 134 |
| [mist-client-troubleshoot](skills/mist-client-troubleshoot/SKILL.md) | Client diagnostics: Marvis AI root cause analysis, session pattern detection, NAC event correlation | 136 |
| [mist-network-issues](skills/mist-network-issues/SKILL.md) | Alarms, events, and Marvis actions: AP offline/reboot, switch problems, bad cables, rogue APs, NAC failures | 135 |
| [mist-network-config](skills/mist-network-config/SKILL.md) | Configuration inspection: DHCP, RF templates, 802.11r, auth server timeouts, WLAN changes, config diff | 134 |
| [mist-switch-port](skills/mist-switch-port/SKILL.md) | Switch port operations: port status, 100 Mbps detection, stack mapping, port profiles, PoE power draw, config comparison | 164 |

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
  install.sh                     # Installer for CLI-based AI apps
  build.sh                       # Build zip archives for Claude Web/Desktop
  dist/                          # Pre-built zip archives for upload
  skills/
    mist-sle/
      SKILL.md
      references/
        metrics.md               # SLE metrics, classifiers, and fixes
    mist-device-inventory/
      SKILL.md
      references/
        ap-capabilities.md       # Wi-Fi standard classification and feature flags
        switch-models.md         # Switch families, roles, port types, PoE
        gateway-models.md        # Gateway/router families and roles
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

### Claude Web & Desktop App

Custom skills can be uploaded to [claude.ai](https://claude.ai) and the Claude Desktop App. Available on Pro, Max, Team, and Enterprise plans.

**Simple skills** (only a `SKILL.md`, no `references/` directory) can be uploaded as a single file. **Complex skills** (with `references/` or `scripts/`) must be uploaded as a `.zip` archive containing the `SKILL.md` and all bundled resources.

#### Build the archives

```bash
./build.sh              # Build all skill archives
./build.sh -s mist-sle  # Build a single skill
./build.sh -c           # Clean and rebuild
```

This creates one `.zip` per skill in the `dist/` directory.

#### Upload to Claude

1. Open a conversation in Claude (Web or Desktop App)
2. Click **"+"** at the bottom of the chat
3. Select **Skills**
4. Click **Manage Skills**
5. Click **"+"** to add a new skill
6. Select **Create Skill**
7. Choose **Upload** and drag & drop the `.zip` file from `dist/` (or the `SKILL.md` directly for simple skills)

Once uploaded, the skill is enabled by default. Claude will use it automatically when your question matches the skill's description. You can toggle skills on/off from the same Manage Skills panel.

> **Note:** Custom skills in Claude.ai are per-user — each team member needs to upload them individually. Skills do not sync between Claude.ai, Claude Code, and the Claude API.

### Claude Code & other CLI-based apps

Use the interactive installer to copy skill folders to the correct path:

```bash
./install.sh            # Interactive menu
./install.sh -a claude  # Install for Claude Code
./install.sh -a goose   # Install for Goose
./install.sh -d /path   # Install to custom path
./install.sh -u -a claude  # Uninstall from Claude Code
```

Run `./install.sh -h` for all options.

Claude Code loads skill metadata at startup and reads the full `SKILL.md` on demand when a question matches. Reference files in `references/` are loaded progressively — only when the skill instructions reference them.

## Key Design Decisions

- **Site resolution**: Skills use `search_mist_data(search_type='sites', filters={name:'...'})` to resolve a site by name directly, avoiding a full site list fetch. The full list is only fetched for org-wide queries that need a complete name map.
- **Pagination**: All list/search calls may return partial results. Skills instruct to check `has_more` and use `next_cursor`.
- **Versioned metrics**: Skills prefer versioned API endpoints (`switch-health-v2`, `wan-link-health-v2`) over their non-versioned equivalents.
- **Progressive disclosure**: Heavy reference content (Wi-Fi model tables, event type catalogs, SLE classifier guides) lives in `references/` and is loaded only when needed.
- **API constraints**: `rogue_events` requires `scope='site'` (no org-wide query). `wireless_client_events` does not support MAC filtering (use `client_sessions` instead).

## License

Apache 2.0 — see [LICENSE](LICENSE)
