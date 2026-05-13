---
name: configure-sifflet-auth
description: Set up Sifflet MCP via ~/.sifflet/config.ini (sifflet configure) and Monitors-as-Code CLI (sifflet configure / SIFFLET_TOKEN)
---

# Configure Sifflet authentication (environment variables)

You still create API tokens in the **Sifflet UI** once ([API token](https://docs.siffletdata.com/docs/generate-an-api-token)).

## MCP (Cursor + `uvx sifflet-mcp`)

**Sifflet configuration file (default):** **`~/.sifflet/config.ini`**. Override with **`SIFFLET_CONFIG_INI`** if needed.

The plugin’s **`mcp.json`** runs the launcher script under **`~/.cursor/plugins/local/sifflet/run-sifflet-mcp.sh`** (via **`${userHome}`** interpolation so the path does not depend on your open workspace). It also declares **`SIFFLET_API_TOKEN`** / **`SIFFLET_BACKEND_URL`** in the MCP **`env`** block, following Cursor’s plugin MCP format. The plugin does **not** ship secrets in the repo.

The launcher reads **`~/.sifflet/config.ini`** when **`SIFFLET_API_TOKEN`** / **`SIFFLET_BACKEND_URL`** are not already set for the MCP process (same **`[APP]`** **`token`** / **`tenant`** / **`backend_url`** as **`sifflet configure`**). It treats unresolved placeholder strings such as **`${SIFFLET_API_TOKEN}`** or **`${env:SIFFLET_API_TOKEN}`** as unset so the ini fallback still runs.

**Recommended:** run **`sifflet configure`** once so **`~/.sifflet/config.ini`** exists with a valid **`[APP]`** section, then reload Cursor (**Developer: Reload Window**).

**Alternative:** If your environment injects **`SIFFLET_API_TOKEN`** and **`SIFFLET_BACKEND_URL`** into the **Cursor application** before MCP starts (MDM, launchctl, etc.), Cursor forwards them via `mcp.json` and the launcher uses those values.

Shell-only exports (**`~/.zshrc`**) are **not** passed to MCP: the **integrated terminal** can show **`echo $SIFFLET_BACKEND_URL`** while the MCP child still has no token.

**Do not** commit real tokens or config files that contain them.

### “Can’t this be two fields in Cursor Settings like other extensions?”

Not with **only** a Cursor plugin: plugins don’t register **Settings** keys (that needs a **VS Code/Cursor extension** with `contributes.configuration`). This plugin’s MCP auth path is Cursor’s MCP **`env`** block plus **`~/.sifflet/config.ini`** fallback via **`run-sifflet-mcp.sh`**.

## CLI (`sifflet code workspace plan|apply`)

Separate from MCP:

| Variable | Notes |
|----------|-------|
| `SIFFLET_TOKEN` | CLI token ([Monitors as Code](https://docs.siffletdata.com/docs/monitors-as-code)) — **not** `SIFFLET_API_TOKEN`. |
| `SIFFLET_BACKEND_URL` | Same host as MCP, typically with **`/api/`**. |

Or run **`sifflet configure`** once so the CLI stores credentials in **`~/.sifflet/`** (see Monitors as Code docs for layout).

## Verify

- **MCP:** Output → **MCP Logs**; run a small discovery request in Agent.
- **CLI:** `sifflet code workspace plan --file workspace.yaml` from a directory that contains your `workspace.yaml`.
