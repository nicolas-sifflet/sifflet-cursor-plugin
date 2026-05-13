#!/usr/bin/env bash
# Launcher for sifflet-mcp: logs non-secret diagnostics to stderr, then execs the real server.
# MCP uses stdout for JSON-RPC — never print debug lines to stdout.
set -euo pipefail

# Cursor may leave ${env:VAR} as a literal string when the GUI process does not define VAR.
# That would block the config.ini fallback (vars look "set"). Treat as unset.
_sifflet_unset_placeholder_env() {
  local name v
  for name in SIFFLET_API_TOKEN SIFFLET_BACKEND_URL SIFFLET_CONFIG_INI; do
    v="${!name-}"
    if [[ -n "$v" && ( "$v" == *'${env:'* || "$v" == *'${'* ) ]]; then
      unset "$name"
    fi
  done
}
_sifflet_unset_placeholder_env
unset -f _sifflet_unset_placeholder_env

# Dock-launched Cursor often has a minimal PATH; uv installs uvx here by default.
if ! command -v uvx >/dev/null 2>&1; then
  export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH:-}"
fi

# When MCP env vars are missing, try the same file as `sifflet configure`:
# ~/.sifflet/config.ini ([APP] tenant, token, optional backend_url).
# Override path with SIFFLET_CONFIG_INI for tests or non-default layouts.
_sifflet_cfg_ini="${SIFFLET_CONFIG_INI:-${HOME}/.sifflet/config.ini}"
if [[ (-z "${SIFFLET_API_TOKEN-}" || -z "${SIFFLET_BACKEND_URL-}") && -f "${_sifflet_cfg_ini}" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    # stdout: export statements only (consumed by eval). Diagnostics on stderr.
    eval "$(python3 - "${_sifflet_cfg_ini}" <<'PY'
import configparser
import os
import shlex
import sys
from pathlib import Path

ini_path = Path(sys.argv[1])
need_token = not (os.environ.get("SIFFLET_API_TOKEN") or "").strip()
need_url = not (os.environ.get("SIFFLET_BACKEND_URL") or "").strip()
if not need_token and not need_url:
    sys.exit(0)

cp = configparser.ConfigParser()
read_ok = cp.read(ini_path, encoding="utf-8")
if not read_ok or "APP" not in cp:
    sys.exit(0)

app = cp["APP"]
tenant = (app.get("tenant") or "").strip()
backend_url = (app.get("backend_url") or "").strip()
token = (app.get("token") or "").strip()

exports = []
if need_token and token:
    exports.append(f"export SIFFLET_API_TOKEN={shlex.quote(token)}")
def _with_https_scheme(raw: str) -> str:
    u = (raw or "").strip()
    if not u:
        return u
    if u.startswith("http://") or u.startswith("https://"):
        return u
    return "https://" + u.lstrip("/")


if need_url:
    url = _with_https_scheme(backend_url)
    if not url and tenant:
        url = f"https://{tenant}.siffletdata.com/api/"
    if url:
        exports.append(f"export SIFFLET_BACKEND_URL={shlex.quote(url)}")

if exports:
    sys.stderr.write(f"[sifflet-mcp] supplemented MCP env from {ini_path}\n")
for line in exports:
    print(line)
PY
)"
  else
    printf '%s\n' "[sifflet-mcp] python3 not found; cannot read ${_sifflet_cfg_ini} (set SIFFLET_API_TOKEN / SIFFLET_BACKEND_URL for the MCP process)" >&2
  fi
fi
unset _sifflet_cfg_ini

# Host-only backend_url in ~/.sifflet/config.ini triggers urllib3 "no scheme" warnings.
if [[ -n "${SIFFLET_BACKEND_URL:-}" && "${SIFFLET_BACKEND_URL}" != http://* && "${SIFFLET_BACKEND_URL}" != https://* ]]; then
  export SIFFLET_BACKEND_URL="https://${SIFFLET_BACKEND_URL#//}"
fi

t="${SIFFLET_API_TOKEN-}"
u="${SIFFLET_BACKEND_URL-}"

if [[ -n "${t}" ]]; then
  token_state="set"
else
  token_state="unset"
fi

if [[ -n "${u}" ]]; then
  url_state="set"
else
  url_state="unset"
fi

printf '%s\n' "[sifflet-mcp] SIFFLET_API_TOKEN: ${token_state} (value not logged)" >&2
printf '%s\n' "[sifflet-mcp] SIFFLET_BACKEND_URL: ${url_state}" >&2
if [[ -n "${u}" ]]; then
  printf '%s\n' "[sifflet-mcp] SIFFLET_BACKEND_URL=${u}" >&2
fi

if [[ -z "${SIFFLET_API_TOKEN:-}" || -z "${SIFFLET_BACKEND_URL:-}" ]]; then
  printf '%s\n' "[sifflet-mcp] Missing SIFFLET_API_TOKEN and/or SIFFLET_BACKEND_URL (still unset after ~/.sifflet/config.ini)." >&2
  printf '%s\n' "[sifflet-mcp] Run: sifflet configure (writes ~/.sifflet/config.ini), or set SIFFLET_API_TOKEN and SIFFLET_BACKEND_URL on the Cursor app process before MCP starts." >&2
  printf '%s\n' "[sifflet-mcp] Docs: commands/configure-sifflet-auth — shell-only exports are not visible to MCP." >&2
  exit 1
fi

if ! command -v uvx >/dev/null 2>&1; then
  printf '%s\n' "[sifflet-mcp] uvx not found. Install uv (https://docs.astral.sh/uv/) or add uvx to PATH (e.g. ~/.local/bin)." >&2
  exit 1
fi

exec uvx sifflet-mcp@latest
