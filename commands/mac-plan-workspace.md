---
name: mac-plan-workspace
description: Run a dry-run plan for a Sifflet Monitors as Code workspace.yaml and review changes before apply
---

# Plan Monitors as Code workspace

## Preconditions

- [Sifflet CLI](https://docs.siffletdata.com/docs/monitors-as-code) installed and authenticated (`sifflet configure` or `SIFFLET_TOKEN` + `SIFFLET_BACKEND_URL`).
- `workspace.yaml` path is known (often `quality/workspace.yaml`).

## Steps

1. From the directory that contains `workspace.yaml` (or pass an absolute path), run:

   ```bash
   sifflet code workspace plan --file workspace.yaml
   ```

2. Read the plan output carefully: created/updated/deleted monitors and any errors.
3. If the plan is wrong, fix YAML or globs and re-run until the plan matches intent.
4. Only after review, use **mac-apply-workspace** (or documented apply flow) to mutate the remote workspace.

## Notes

- Workspace-managed monitors become **read-only in the UI**; set expectations with the user.
- If the user relies on MCP instead of CLI for discovery only, remind them that **plan/apply** still go through the CLI (or their CI) unless they use another approved path.
- The plan output is the source of truth for what apply will change. Before apply, follow the **destructive-change confirmation protocol** in **sifflet-quality-as-code**: surface the exact deletions/recreations and collect the typed confirmation token. Do not auto-chain plan → apply.
