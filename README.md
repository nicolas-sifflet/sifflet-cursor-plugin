# Sifflet Cursor Plugin

Bring Sifflet data observability into Cursor. This plugin connects agents to Sifflet through the official MCP server and adds guidance for writing [Monitors as Code](https://docs.siffletdata.com/docs/monitors-as-code).

## What You Get

- **Sifflet MCP** for catalog, monitor, incident, and lineage discovery from Agent chat.
- **Quality as Code skills** for drafting and reviewing `workspace.yaml` and monitor YAML.
- **Rules and commands** that keep monitor changes reviewable before they are applied.

## Requirements

- A Sifflet account and API token.
- Cursor with plugin and MCP support.
- [`uv`](https://docs.astral.sh/uv/) available on your PATH so Cursor can run `uvx sifflet-mcp`.
- The Sifflet CLI if you want to run `sifflet code workspace plan` or `apply`.

## Installation

Once the plugin is published, install **Sifflet** from Cursor's plugin marketplace.

For local testing, clone this repository and sync it into Cursor's local plugins folder:

```bash
mkdir -p ~/.cursor/plugins/local
rm -rf ~/.cursor/plugins/local/sifflet
mkdir ~/.cursor/plugins/local/sifflet
cp -R .cursor-plugin assets commands rules skills mcp.json run-sifflet-mcp.sh README.md ~/.cursor/plugins/local/sifflet/
```

The final folder should be:

```text
~/.cursor/plugins/local/sifflet/
```

Reload Cursor after installing or updating the local plugin.

## Getting Started

Install the plugin, then authenticate Sifflet once:

```bash
sifflet configure
```

This writes `~/.sifflet/config.ini`. The bundled MCP launcher reads that file when Cursor has not been started with `SIFFLET_API_TOKEN` and `SIFFLET_BACKEND_URL` in its environment.

Reload Cursor, enable the `sifflet` MCP server in Cursor settings, then ask Agent chat a Sifflet question:

```text
Find datasets related to customer orders in Sifflet.
```

## Example Prompts

Catalog and lineage:

```text
Search Sifflet for the orders dataset and show its downstream assets.
```

```text
Which monitors are attached to this dataset?
```

Monitors as Code:

```text
Create a Sifflet monitor YAML for freshness on this table.
```

```text
Review this workspace.yaml before I run a plan.
```

```text
Run a dry-run plan for quality/workspace.yaml and summarize the changes.
```

## Included

### MCP Server

The plugin registers the `sifflet` MCP server through `mcp.json`. It starts `run-sifflet-mcp.sh`, which launches `sifflet-mcp` with `uvx`.

Authentication is resolved in this order:

1. `SIFFLET_API_TOKEN` and `SIFFLET_BACKEND_URL` from the Cursor app process.
2. `~/.sifflet/config.ini`, usually created by `sifflet configure`.

Shell-only exports in `~/.zshrc` or another terminal profile are not always visible to MCP, because MCP servers are started by the Cursor app process.

### Skills

- `sifflet-mcp` - explore catalog assets, monitors, incidents, and lineage before changing data or YAML.
- `sifflet-quality-as-code` - draft and refine Sifflet monitor and workspace YAML using MCP context and the Monitors as Code schema.

### Rules

- `sifflet-mac-yaml` - conventions for safe Monitors as Code YAML changes.

### Commands

- `configure-sifflet-auth` - explain MCP and CLI authentication.
- `mac-plan-workspace` - run and review a dry-run plan.
- `mac-apply-workspace` - apply a reviewed workspace change.

## Monitors as Code

Use MCP for discovery and the Sifflet CLI for workspace changes:

```bash
sifflet code workspace plan --file workspace.yaml
sifflet code workspace apply --file workspace.yaml
```

For CLI auth, use `sifflet configure` or set `SIFFLET_TOKEN` and `SIFFLET_BACKEND_URL`. `SIFFLET_TOKEN` is for the CLI; `SIFFLET_API_TOKEN` is for MCP.

## Troubleshooting

If MCP tools do not appear, reload Cursor and confirm the `sifflet` MCP server is enabled in settings.

If authentication fails, run `sifflet configure` again and check that `~/.sifflet/config.ini` contains a valid `[APP]` section. You can also start Cursor with `SIFFLET_API_TOKEN` and `SIFFLET_BACKEND_URL` already set in the app environment.

If `uvx` is missing, install `uv` and restart Cursor.

## Local Development

Cursor loads local plugins from `~/.cursor/plugins/local/<name>/`. This plugin expects the local folder name to be `sifflet`, because `mcp.json` points to `~/.cursor/plugins/local/sifflet/run-sifflet-mcp.sh`.

From this repository:

```bash
mkdir -p ~/.cursor/plugins/local
rm -rf ~/.cursor/plugins/local/sifflet
mkdir ~/.cursor/plugins/local/sifflet
cp -R .cursor-plugin assets commands rules skills mcp.json run-sifflet-mcp.sh README.md ~/.cursor/plugins/local/sifflet/
```

Reload Cursor after copying changes.

Remove the local copy:

```bash
rm -rf ~/.cursor/plugins/local/sifflet
```

## Publishing

Publish from a dedicated public repository or generated mirror that contains only this plugin tree. The manifest keeps `logo` as `assets/logo.svg` so the Cursor Marketplace can resolve it after publication.

## Links

- [Sifflet MCP server](https://docs.siffletdata.com/docs/sifflet-mcp-server)
- [Monitors as Code](https://docs.siffletdata.com/docs/monitors-as-code)
- [Monitor schema](https://docs.siffletdata.com/docs/monitor-schema)
- [Workspace schema](https://docs.siffletdata.com/docs/workspace-schema)
