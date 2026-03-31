# Mist MCP Skills

Skills for LLMs using the [Juniper Mist MCP Server](https://www.juniper.net/documentation/us/en/software/mist/mist-aiops/shared-content/topics/concept/juniper-mist-mcp-claude.html). These skills teach Claude (or other compatible LLMs) how to effectively troubleshoot, analyse, and interact with Juniper Mist AI networks.

## About This Repository

This repository contains skills that extend LLM capabilities when working with the Mist platform through the MCP server. Each skill provides structured workflows, metric references, and step-by-step guidance for specific network operations.

Skills are self-contained folders with a `SKILL.md` file containing instructions and metadata that the LLM follows when the skill is active.

## Available Skills

| Skill | Description |
|-------|-------------|
| [mist-client-troubleshoot](./skills/mist-client-troubleshoot) | Marvis AI-powered workflow for diagnosing client connectivity issues (WiFi, wired, WAN) |
| [mist-sle-wireless](./skills/mist-sle-wireless) | Analyse Wireless SLE metrics: coverage, capacity, time-to-connect, roaming, throughput |
| [mist-sle-wired](./skills/mist-sle-wired) | Analyse Wired SLE metrics: switch health, throughput, bandwidth, client connectivity |
| [mist-sle-wan](./skills/mist-sle-wan) | Analyse WAN SLE metrics: gateway health, WAN link quality, application health |

## Usage

### Claude Desktop

1. Configure the [Juniper Mist MCP Server](https://www.juniper.net/documentation/us/en/software/mist/mist-aiops/shared-content/topics/concept/juniper-mist-mcp-claude.html) in your Claude Desktop settings
2. Add skill files to your conversation by attaching the relevant `SKILL.md` or adding them to your project knowledge
3. Claude will follow the structured workflows when you ask about client troubleshooting or SLE metrics

### Manual

Copy the relevant `SKILL.md` content into your system prompt or attach it to your conversation context.

## Skill Structure

Each skill follows this format:

```markdown
---
name: skill-name
description: >
  Clear description of when and how to use this skill.
  Include trigger phrases and keywords.
---

# Skill Title

[Workflow instructions, metric references, examples]
```

## Requirements

- [Juniper Mist MCP Server](https://www.juniper.net/documentation/us/en/software/mist/mist-aiops/shared-content/topics/concept/juniper-mist-mcp-claude.html) configured in Claude Desktop
- Juniper Mist API token with appropriate permissions
- Claude Desktop with Node.js 18+

## Disclaimer

These skills are provided for demonstration and operational purposes. Always verify recommendations and actions in your specific environment before applying changes to production networks.

## License

Apache 2.0
