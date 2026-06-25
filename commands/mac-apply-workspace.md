---
name: mac-apply-workspace
description: Apply a reviewed Sifflet Monitors as Code workspace.yaml after a successful plan
---

# Apply Monitors as Code workspace

## Preconditions

- A recent successful `sifflet code workspace plan --file workspace.yaml` with output reviewed and approved.
- User explicitly wants to **mutate** the remote workspace (not a dry run).

## Steps

1. Re-run plan if YAML changed since the last review:

   ```bash
   sifflet code workspace plan --file workspace.yaml
   ```

2. Apply:

   ```bash
   sifflet code workspace apply --file workspace.yaml
   ```

3. Confirm success in CLI output; suggest verifying monitors in the Sifflet UI if appropriate.

## Safety (mandatory — see the destructive-change confirmation protocol)

Apply mutates the remote workspace and can permanently delete or recreate monitors. Follow
the **destructive-change confirmation protocol** in the **sifflet-quality-as-code** skill:

1. Run `sifflet code workspace plan --file workspace.yaml` and show the output.
2. List every monitor the plan will **delete** and every monitor it will **recreate**
   (changed `id`, or changed datasets behind a `friendlyId` — recreation loses history). For
   large bulk changes, show grouped counts plus a representative list.
3. Ask the user to type **`CONFIRM SIFFLET APPLY`**. If the plan deletes or recreates N
   monitors, also require **`DELETE <N>`**.
4. Only proceed on an exact token match. A casual "yes" is not sufficient.
5. Never run `apply --auto-approve` interactively; suggest it only for reviewed CI/CD.

A bundled hook also surfaces a native confirmation prompt for `apply`, `--auto-approve`,
monitor-file removal, and mutating MCP calls. Treat it as a backstop, not a substitute.
