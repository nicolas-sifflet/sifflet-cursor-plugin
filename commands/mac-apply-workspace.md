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

## Safety

- Warn about **deletions** and **id changes** that can retire or replace monitors.
- Never run apply against production without the user’s confirmation when context is ambiguous.
